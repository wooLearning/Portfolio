// =============================================================================
// 다중 에이전트 주차장 시뮬레이션 시스템
// =============================================================================
// 알고리즘: D* Lite + WHCA* + WFG(SCC) + Partial CBS / A* / D* Lite
// 주요 기능:
//   - 맵 선택 (1~5): Map#1 = 기본, Map#2~5 = 스트레스 테스트
//   - 대화형 제어: 일시정지, 스텝 실행, 속도 조절, 종료
//   - 깜빡임 방지 실시간 렌더링 'F'
// =============================================================================

#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <time.h>
#include <stdarg.h>
#include <ctype.h>

#include <windows.h>

#include <psapi.h>
#include <conio.h>
#ifdef _WIN32
#pragma comment(lib, "psapi.lib")
#endif
/**
 * @brief Windows 환경에서 밀리초 단위 대기를 수행하는 간단한 래퍼 매크로입니다.
 * @param ms 대기할 밀리초(ms)
 */
#define sleep_ms(ms) Sleep(ms)

 /**
  * @brief 포맷 문자열을 버퍼에 안전하게 이어붙이는 헬퍼 매크로입니다.
  *        snprintf 반환값을 사용하여 포인터/남은 용량을 자동 갱신합니다.
  * @param P    기록 포인터(char*)
  * @param REM  남은 용량(size_t)
  * @param ...  printf 스타일 포맷 가변 인자
  */
#ifndef APPEND_FMT
#define APPEND_FMT(P, REM, /*fmt, ...*/ ...)                            \
    do {                                                                \
        int __w = snprintf((P), (REM), __VA_ARGS__);                    \
        if (__w < 0) __w = 0;                                           \
        if ((size_t)__w > (REM)) __w = (int)(REM);                      \
        (P) += __w;                                                     \
        (REM) -= __w;                                                   \
    } while (0)
#endif


  // =============================================================================
  // 섹션 1: 상수 및 설정
  // =============================================================================
  /**
   * @brief 전역 상수/매크로 및 UI·알고리즘 기본 설정을 모은 섹션입니다.
   */
   /**
    * @brief 전역 상수 및 기본 버퍼 크기 설정
    * - TRUE/FALSE: 간단한 불리언 상수
    * - INPUT_BUFFER_SIZE: 콘솔 입력 버퍼 크기
    * - DISPLAY_BUFFER_SIZE: 텍스트 UI 렌더용 버퍼 크기
    */
#define TRUE 1
#define FALSE 0
#define INPUT_BUFFER_SIZE 500
#define DISPLAY_BUFFER_SIZE 512000

    /**
     * @brief ANSI 색상 코드 상수 (가상 터미널 활성화 시 컬러 출력에 사용)
     */
     // --- ANSI 색상 코드 ---
#define C_NRM "\x1b[0m"
#define C_RED "\x1b[31m"
#define C_GRN "\x1b[32m"
#define C_YEL "\x1b[33m"
#define C_BLU "\x1b[34m"
#define C_MAG "\x1b[35m"
#define C_CYN "\x1b[36m"
#define C_WHT "\x1b[37m"
#define C_GRY "\x1b[90m"
#define C_B_RED "\x1b[1;31m"
#define C_B_GRN "\x1b[1;32m"
#define C_B_YEL "\x1b[1;33m"
#define C_B_MAG "\x1b[1;35m"
#define C_B_CYN "\x1b[1;36m"
#define C_B_WHT "\x1b[1;37m"

/**
 * @brief 에이전트 색상 팔레트(A..J) 매핑. 각 인덱스는 에이전트 ID에 대응합니다.
 */
 // --- 에이전트 색상 팔레트 (A..J) ---
static const char* AGENT_COLORS[10] = {
C_B_CYN, C_B_YEL, C_B_MAG, C_B_GRN, C_B_RED,
C_B_WHT, C_CYN,   C_YEL,   C_MAG,   C_GRN
};


/**
 * @brief 그리드/에이전트 전역 설정
 * - GRID_WIDTH/HEIGHT: 맵 크기
 * - MAX_AGENTS: 지원 에이전트 수
 * - MAX_GOALS: 최대 주차칸 개수(그리드 전셀 상한)
 * - INF: 경로 비용 무한대 표현
 */
 // --- 그리드 및 에이전트 설정 ---
#define GRID_WIDTH  82
#define GRID_HEIGHT 42
#define MAX_AGENTS  10
#define MAX_GOALS   (GRID_WIDTH*GRID_HEIGHT)
#define INF 1e18
#define NUM_DIRECTIONS 4
#ifndef DIR4_COUNT
#define DIR4_COUNT 4
#endif

/**
 * @brief 4방향(상우하좌) 및 미정 상태를 나타내는 방향 열거형
 */
typedef enum {
    DIR_NONE = -1,
    DIR_UP = 0,
    DIR_RIGHT = 1,
    DIR_DOWN = 2,
    DIR_LEFT = 3
} AgentDir;

/**
 * @brief 시뮬레이션 전역 매개변수
 * - DISTANCE_BEFORE_CHARGE: 충전 판단을 위한 누적 이동 거리 상한
 * - CHARGE_TIME: 충전 소요 틱
 * - MAX_CHARGE_STATIONS: 최대 충전소 수
 * - MAX_PHASES: 사용자 정의 시나리오 단계 수 상한
 * - REALTIME_MODE_TIMELIMIT: 실시간 모드 총 틱 제한
 * - DASHBOARD_INTERVAL_STEPS: 실시간 대시보드 출력 간격
 * - MAX_TASKS: 실시간 대기열 최대 작업 수
 * - MAX_SPEED_MULTIPLIER: 최대 배속
 */
 // --- 시뮬레이션 매개변수 ---
#define DISTANCE_BEFORE_CHARGE 300.0
#define CHARGE_TIME 20
#define MAX_CHARGE_STATIONS 10
#define MAX_PHASES 20
#define REALTIME_MODE_TIMELIMIT 1000000
#define DASHBOARD_INTERVAL_STEPS 2500
#define MAX_TASKS 50
#define MAX_SPEED_MULTIPLIER 10000.0f
#define EVENT_GENERATION_INTERVAL 10
// 정리 단계에서 강제 유휴화를 적용하기 전 대기할 스텝 수
#ifndef CLEANUP_FORCE_IDLE_AFTER_STEPS
#define CLEANUP_FORCE_IDLE_AFTER_STEPS 11
#endif

/**
 * @brief UI 버퍼 관련 상수
 * - LOG_BUFFER_LINES: 순환 로그 줄 수
 * - LOG_BUFFER_WIDTH: 로그 한 줄 너비
 * - STATUS_STRING_WIDTH: 상태 패널 고정 폭
 */
 // --- UI 설정 ---
#define LOG_BUFFER_LINES 5
#define LOG_BUFFER_WIDTH 256
#define STATUS_STRING_WIDTH 25

/**
 * @brief UI 타이밍 및 렌더링 간격 설정
 * - PAUSE_POLL_INTERVAL_MS: 일시정지 상태 폴링 주기
 * - RENDER_STRIDE_MAX/MIN: 프레임 스킵 범위
 */
 // --- UI 타이밍 및 렌더링 간격 ---
#ifndef PAUSE_POLL_INTERVAL_MS
#define PAUSE_POLL_INTERVAL_MS 50
#endif
#ifndef RENDER_STRIDE_MAX
#define RENDER_STRIDE_MAX 8
#endif
#ifndef RENDER_STRIDE_MIN
#define RENDER_STRIDE_MIN 1
#endif

/**
 * @brief 작업/우선순위/교착 가중치 설정
 * - TASK_ACTION_TICKS: 주차/출차 작업 대기 틱
 * - PRIORITY_*: 상태별 우선순위 기본값
 * - STUCK_BOOST_*: stuck 정도에 따른 보정
 */
 // --- 작업 및 우선순위 상수 ---
#ifndef TASK_ACTION_TICKS
#define TASK_ACTION_TICKS 10         // 주차/출차 작업 대기 틱 수
#endif
#ifndef PRIORITY_RETURNING_WITH_CAR
#define PRIORITY_RETURNING_WITH_CAR 3
#endif
#ifndef PRIORITY_GOING_TO_CHARGE
#define PRIORITY_GOING_TO_CHARGE 2
#endif
#ifndef PRIORITY_MOVING_TASK
#define PRIORITY_MOVING_TASK 1       // GOING_TO_PARK / GOING_TO_COLLECT 상태 우선순위
#endif
#ifndef STUCK_BOOST_MULT
#define STUCK_BOOST_MULT 10
#endif
#ifndef STUCK_BOOST_HARD
#define STUCK_BOOST_HARD 1000        // stuck_steps >= DEADLOCK_THRESHOLD일 때 적용
#endif

/**
 * @brief 교착 상태 판단 임계치 설정(stuck 연속 틱 수)
 */
 // --- 교착 상태 처리 ---
#define DEADLOCK_THRESHOLD 5

/**
 * @brief WHCA* 호라이즌 설정(최소/최대/초기값)
 */
 // --- WHCA* 호라이즌 설정 ---
#define MIN_WHCA_HORIZON 5
#define MAX_WHCA_HORIZON 11
static int g_whca_horizon = 5;

/**
 * @brief 대기 그래프(WFG) 및 Partial CBS 관련 한도 설정
 */
 // --- WFG 및 CBS 매개변수 
#define MAX_WAIT_EDGES 64
#define MAX_CBS_GROUP  5
#define MAX_CBS_CONS   64
#define MAX_CBS_NODES  128
#define CBS_MAX_EXPANSIONS 64

/**
 * @brief ST-A*용 정적 버퍼 인덱스 상한 (메모리 선할당 크기)
 */
 // --- ST-A* 정적 버퍼 크기 ---
#define MAX_TOT (((MAX_WHCA_HORIZON)+1) * GRID_WIDTH * GRID_HEIGHT)

/**
 * @brief 텍스트 UI(상태/맵/로그)를 한 번에 모아 출력하기 위한 전역 버퍼
 */
static char g_display_buf[DISPLAY_BUFFER_SIZE];


// =============================================================================
// 섹션 2: 데이터 구조
// =============================================================================
// D* Lite 우선순위 큐에서 사용하는 키 값 구조체
typedef struct { double k1; double k2; } Key;
// Key 구조체 생성 헬퍼 함수
static inline Key make_key(double a, double b) { Key k; k.k1 = a; k.k2 = b; return k; }

// 그리드 내의 한 칸(노드)을 나타내는 구조체
typedef struct Node {
    int x, y;               // 노드의 그리드 좌표
    int is_obstacle;        // 장애물 여부 (영구)
    int is_goal;            // 주차 공간 여부
    int is_temp;            // 임시 장애물 여부 (계획용)
    int is_parked;          // 차량이 주차되어 있는지 여부
    int reserved_by_agent;  // 다른 에이전트에 의해 예약되었는지 여부 (-1: 예약 없음)
} Node;

// --- 에이전트 상태 열거형 ---
typedef enum {
    IDLE, GOING_TO_PARK, RETURNING_HOME_EMPTY, GOING_TO_COLLECT,
    RETURNING_WITH_CAR, GOING_TO_CHARGE, CHARGING, RETURNING_HOME_MAINTENANCE
} AgentState;

// --- 시나리오 타입 ---
typedef enum { PARK_PHASE, EXIT_PHASE } PhaseType;
typedef struct { PhaseType type; int task_count; char type_name[10]; } DynamicPhase;
typedef enum { TASK_NONE, TASK_PARK, TASK_EXIT } TaskType;
typedef struct TaskNode { TaskType type; int created_at_step; struct TaskNode* next; } TaskNode;
typedef enum { MODE_UNINITIALIZED, MODE_CUSTOM, MODE_REALTIME } SimulationMode;

// --- 경로 계획 알고리즘 선택 ---
typedef enum {
    PATHALGO_DEFAULT = 0,       // 통합: WHCA* + D* Lite + WFG(SCC) + Partial CBS
    PATHALGO_ASTAR_SIMPLE = 1,  // 단순 A* 한 스텝 계획
    PATHALGO_DSTAR_BASIC = 2    // 기본 예약/충돌 처리를 갖춘 증분형 D* Lite
} PathAlgo;

// --- 그리드 맵 구조체 ---
typedef struct {
    Node grid[GRID_HEIGHT][GRID_WIDTH];
    Node* goals[MAX_GOALS];
    int num_goals;
    Node* charge_stations[MAX_CHARGE_STATIONS];
    int num_charge_stations;
} GridMap;

// --- 증분형 D* Lite 탐색 셀 (에이전트별 데이터) ---
typedef struct {
    double g, rhs;      // D* Lite의 g값과 rhs값
    Key key;            // 우선순위 큐 정렬에 사용되는 키
    int in_pq;          // 우선순위 큐(open list) 포함 여부
    int pq_index;       // 우선순위 큐 내의 인덱스 (힙 연산용)
} SearchCell;

// --- D* Lite용 우선순위 큐 (힙 구현) ---
typedef struct {
    Node** nodes;       // 노드 포인터 배열 (힙)
    int size;           // 현재 큐에 저장된 요소의 수
    int capacity;       // 큐의 최대 용량
} NodePQ;

// Pathfinder 구조체 전방 선언
struct Pathfinder_;
struct Agent_;  // Agent 전방 선언
typedef struct Agent_ Agent;  // Agent 타입 별칭
// D* Lite 알고리즘의 인스턴스를 관리하는 구조체 (에이전트별로 소유)
typedef struct Pathfinder_ {
    NodePQ pq;                                  // 우선순위 큐 (open list)
    SearchCell cells[GRID_HEIGHT][GRID_WIDTH];  // 각 셀의 D* Lite 데이터
    Node* start_node;                           // 현재 에이전트의 시작 위치 (s_start)
    Node* goal_node;                            // 최종 목표 위치 (t, rhs=0)
    Node* last_start;                           // 이전 스텝의 시작 위치 (km 계산용)
    double km;                                  // D* Lite의 키 수정자 (key modifier)
    const struct Agent_* agent;                 // 이 Pathfinder를 소유한 에이전트 (블록 체크용)
    // --- 알고리즘 메트릭 (스텝별 집계용) ---
    unsigned long long nodes_expanded_this_call; // 이번 호출에서 확장된 노드 수
    unsigned long long heap_moves_this_call;     // 이번 호출에서 발생한 힙 이동 수
    unsigned long long nodes_generated_this_call;  // nodes pushed into OPEN during this call
    unsigned long long valid_expansions_this_call; // relaxations committed during this call
} Pathfinder;

// --- WHCA* 시간 확장 예약 테이블 ---
typedef struct {
    int occ[MAX_WHCA_HORIZON + 1][GRID_HEIGHT][GRID_WIDTH];
} ReservationTable;

// --- 대기 그래프 (충돌 원인을 포함한 시간 확장형) ---
typedef enum { CAUSE_VERTEX = 0, CAUSE_SWAP = 1 } CauseType;
typedef struct {
    int from_id, to_id;   // 대기 관계 (from_id가 to_id를 기다림)
    int t;                // 충돌이 발생한 시간 (1..H)
    CauseType cause;      // 충돌 원인 (정점 또는 교차)
    int x1, y1;           // 충돌 위치 1 (정점의 경우 여기만 사용)
    int x2, y2;           // 충돌 위치 2 (교차의 경우 사용)
} WaitEdge;

// --- 부분 팀 CBS (Conflict-Based Search) 제약 조건 ---
typedef struct {
    int agent;      // 제약 조건이 적용될 에이전트 ID
    int t;          // 제약 조건 시간
    int is_edge;    // 0: 정점 제약, 1: 간선 제약
    int x, y;       // 정점 좌표 또는 간선의 시작 좌표
    int tox, toy;   // 간선의 도착 좌표
} CBSConstraint;

// CBS 고수준 탐색 노드
typedef struct {
    CBSConstraint cons[MAX_CBS_CONS];                   // 현재 노드에 적용된 제약 조건 목록
    int ncons;                                          // 제약 조건의 수
    Node* plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1];      // 제약 조건을 만족하는 각 에이전트의 경로 계획
    double cost;                                        // 현재 계획의 총 비용
} CBSNode;


// --- 회전 헬퍼 함수 (Agent 구조체보다 먼저 배치하여 접근 가능하도록 함) ---
// 델타 값으로부터 방향 계산
static inline AgentDir dir_from_delta(int dx, int dy) {
    if (dx == 1 && dy == 0) return DIR_RIGHT;
    if (dx == -1 && dy == 0) return DIR_LEFT;
    if (dx == 0 && dy == -1) return DIR_UP;
    if (dx == 0 && dy == 1) return DIR_DOWN;
    return DIR_NONE;
}

// 두 방향 간 회전에 필요한 스텝 수 계산
static inline int dir_turn_steps(AgentDir from, AgentDir to) {
    if (from == DIR_NONE || to == DIR_NONE) return 0;
    int diff = ((int)to - (int)from + NUM_DIRECTIONS) % NUM_DIRECTIONS;
    return diff <= 2 ? diff : 4 - diff;;
}

// --- 이동 및 기하 헬퍼 (통합) ---
// 회전 대기 시간 (90도 회전 시 총 대기 틱)
#ifndef TURN_90_WAIT
#define TURN_90_WAIT 2
#endif

// 4방향 기본 오프셋 (상단 정렬)
// 인덱스: 0=UP, 1=DOWN, 2=RIGHT, 3=LEFT
static const int DIR4_X[4] = { 0, 0, 1, -1 };
static const int DIR4_Y[4] = { 1, -1, 0, 0 };
// 5방향 오프셋 (정지 포함)
// 인덱스 0 = STAY, 이후 RIGHT/LEFT/DOWN/UP
static const int DIR5_X[5] = { 0, 1, -1, 0, 0 };
static const int DIR5_Y[5] = { 0, 0,  0, 1,-1 };
#ifndef DIR5_COUNT
#define DIR5_COUNT 5
#endif

// --- 맨해튼 거리 헬퍼 (중복 수식 제거) ---
// 노드 간 맨해튼 거리 계산
static inline double manhattan_nodes(const Node* a, const Node* b) {
    return fabs((double)a->x - (double)b->x) + fabs((double)a->y - (double)b->y);
}
// 좌표 간 맨해튼 거리 계산
static inline double manhattan_xy(int x1, int y1, int x2, int y2) {
    return fabs((double)x1 - (double)x2) + fabs((double)y1 - (double)y2);
}

// --- 임시 장애물 마킹 (계획 단계 전용) ---
// - 계획 중 충돌 회피를 위해 동적으로 장애물을 설정하고 해제하는 기능
// - 사용 후에는 반드시 temp_unmark_all 또는 관련 컨텍스트 정리 함수를 호출해야 함
#ifndef TEMP_MARK_MAX
#define TEMP_MARK_MAX 128
#endif
typedef struct {
    Node* nodes[TEMP_MARK_MAX];
    int count;
} TempMarkList;
// 임시 마킹 리스트 초기화
static inline void temp_mark_init(TempMarkList* l) { if (l) l->count = 0; }
// 노드를 임시 장애물로 마킹
static inline void temp_mark_node(TempMarkList* l, Node* n) {
    if (!l || !n) return;
    if (!n->is_temp) {
        n->is_temp = TRUE;
        if (l->count < TEMP_MARK_MAX) l->nodes[l->count++] = n;
    }
}
// 모든 임시 마킹 해제
static inline void temp_unmark_all(TempMarkList* l) {
    if (!l) return;
    for (int i = 0; i < l->count; i++) if (l->nodes[i]) l->nodes[i]->is_temp = FALSE;
    l->count = 0;
}

// --- 임시 마킹 정리 + D* Lite 환경 변화 통지 ---
// 주의: 증분 탐색 알고리즘의 일관성을 유지하려면, 임시 장애물 해제 시
// 해당 셀의 상태 변화를 D* Lite에 통지(notify)해야 합니다.
// 이 기능은 관련 프로토타입 선언 이후에 함수 본문이 정의됩니다.

// 에이전트의 모든 상태와 속성을 관리하는 구조체
typedef struct Agent_ {
    int id;                     // 에이전트 고유 ID
    char symbol;                // 화면에 표시될 문자 (A, B, ...)
    Node* pos;                  // 현재 위치
    Node* home_base;            // 기지 위치
    Node* goal;                 // 현재 목표 위치
    AgentState state;           // 현재 상태 (IDLE, GOING_TO_PARK 등)
    double total_distance_traveled; // 총 이동 거리 (충전 판단용)
    int charge_timer;           // 충전 잔여 시간 (틱)
    int action_timer;           // 주차/출차 작업 잔여 시간 (틱)
    AgentDir heading;           // 현재 바라보는 방향
    int rotation_wait;          // 회전 대기 시간 (틱)

    Pathfinder* pf;             // D* Lite 경로 탐색기 인스턴스

    int stuck_steps;            // 연속적으로 움직이지 못한 스텝 수 (교착 상태 감지용)
    // --- 작업별 성능 측정 메트릭 ---
    int metrics_task_active;        // 현재 작업에 대한 성능 측정이 활성화되었는지 여부
    int metrics_task_start_step;    // 작업 시작 시점의 시뮬레이션 스텝
    double metrics_distance_at_start; // 작업 시작 시점의 총 이동 거리
    int metrics_turns_current;      // 현재 작업 동안 발생한 회전 수
} Agent;

// --- 회전 및 이동 공통 처리 ---
// current에서 desired로 이동 시 헤딩 변화에 따라 대기 또는 이동을 결정
// 90° 회전 시 TURN_90_WAIT 만큼 대기하며, 헤딩 미정(DIR_NONE)인 첫 이동은 즉시 진행
static inline void agent_apply_rotation_and_step(Agent* ag, Node* current, Node* desired, Node** out_next) {
    if (!ag || !current || !out_next) return;
    *out_next = current;
    if (!desired || desired == current) return;

    int dx = desired->x - current->x;
    int dy = desired->y - current->y;
    AgentDir new_heading = dir_from_delta(dx, dy);
    if (new_heading == DIR_NONE) return;

    if (ag->heading == DIR_NONE) {
        ag->heading = new_heading;
        *out_next = desired;
        return;
    }

    int turn_steps = dir_turn_steps(ag->heading, new_heading);
    if (turn_steps == 1) {
        ag->rotation_wait = TURN_90_WAIT - 1;
        ag->heading = new_heading;
        ag->metrics_turns_current++;
        return;
    }
    ag->heading = new_heading;
    *out_next = desired;
}

// 모든 에이전트를 관리하는 구조체
typedef struct {
    Agent agents[MAX_AGENTS];
    int total_cars_parked;  // 현재 주차장에 주차된 차량의 총 수
} AgentManager;

// 시나리오 진행 상태를 관리하는 구조체
typedef struct {
    SimulationMode mode;            // 시뮬레이션 모드 (사용자 정의, 실시간)
    int time_step;                  // 현재 시뮬레이션 시간 (틱)
    int simulation_speed;           // 시뮬레이션 속도 (스텝 간 대기 시간 ms)
    float speed_multiplier;         // 속도 배율
    DynamicPhase phases[MAX_PHASES]; // 사용자 정의 시나리오의 단계 목록
    int num_phases;                 // 총 단계 수
    int current_phase_index;        // 현재 진행 중인 단계 인덱스
    int tasks_completed_in_phase;   // 현재 단계에서 완료된 작업 수
    TaskNode* task_queue_head;      // 실시간 모드의 작업 대기열 헤드
    TaskNode* task_queue_tail;      // 실시간 모드의 작업 대기열 테일
    int task_count;                 // 대기열에 있는 총 작업 수
    int park_chance;                // 실시간 모드에서 주차 요청이 발생할 확률 (0-100)
    int exit_chance;                // 실시간 모드에서 출차 요청이 발생할 확률 (0-100)


} ScenarioManager;

// 로그 메시지를 관리하는 구조체 (순환 버퍼)
typedef struct {
    char logs[LOG_BUFFER_LINES][LOG_BUFFER_WIDTH];
    int log_head;       // 가장 오래된 로그의 인덱스
    int log_count;      // 현재 저장된 로그의 수
} Logger;

// Simulation 구조체 전방 선언 (렌더러 파사드 가상 함수 테이블 시그니처용)
struct Simulation_;

// --- 알고리즘 런타임 메트릭 섀도우 (g_metrics의 미러) ---
typedef struct {
    int whca_h;
    int wf_edges_last;
    long long wf_edges_sum;
    int scc_last;
    long long scc_sum;
    int cbs_ok_last;
    int cbs_exp_last;
    long long cbs_success_sum;
    long long cbs_fail_sum;
} AlgoRTMetrics;

// --- 플래너 전략 (전략 패턴) ---
// 다른 경로 계획 알고리즘으로 쉽게 교체할 수 있도록 함수 포인터를 사용
typedef struct PlannerVTable {
    void (*plan_step)(AgentManager*, GridMap*, Logger*, Node* next_pos[MAX_AGENTS]);
} PlannerVTable;

typedef struct Planner {
    PlannerVTable vtbl;
} Planner;

// --- 렌더러 파사드 (파사드 패턴) ---
// 렌더링 구현을 캡슐화하고 단순한 인터페이스를 제공
typedef struct RendererFacadeVTable {
    void (*draw_frame)(struct Simulation_*, int is_paused);
} RendererFacadeVTable;

typedef struct RendererFacade_ {
    RendererFacadeVTable vtbl;
} RendererFacade;

// 시뮬레이션의 모든 상태를 포함하는 최상위 구조체
typedef struct Simulation_ {
    GridMap* map;
    AgentManager* agent_manager;
    ScenarioManager* scenario_manager;
    Logger* logger;
    int map_id;                             // 현재 선택된 맵 번호(1~5)
    PathAlgo path_algo;                     // 선택된 경로 계획 알고리즘
    Planner planner;                        // 전략 패턴에 따른 현재 플래너
    RendererFacade renderer;                // 렌더링을 담당하는 파사드
    int whca_horizon_shadow;                // 전역 호라이즌 값의 복사본 (관찰용)
    AlgoRTMetrics algo_rt_metrics_shadow;   // g_metrics의 복사본 (관찰/집계용)
    double total_cpu_time_ms;               // 시뮬레이션 총 CPU 시간 (ms)
    double last_step_cpu_time_ms;           // 마지막 스텝의 CPU 시간 (ms)
    double max_step_cpu_time_ms;            // 가장 오래 걸린 스텝의 CPU 시간 (ms)
    double phase_cpu_time_ms[MAX_PHASES];   // 각 단계별 누적 CPU 시간
    int phase_step_counts[MAX_PHASES];      // 각 단계별 총 스텝 수
    int phase_first_step[MAX_PHASES];       // 각 단계가 시작된 스텝 번호
    int phase_last_step[MAX_PHASES];        // 각 단계가 종료된 스텝 번호
    int phase_completed_tasks[MAX_PHASES];  // 각 단계에서 완료된 작업 수
    double post_phase_cpu_time_ms;          // 모든 단계 완료 후 정리 단계의 CPU 시간
    int post_phase_step_count;              // 정리 단계의 스텝 수
    int post_phase_first_step;              // 정리 단계 시작 스텝 번호
    int post_phase_last_step;               // 정리 단계 종료 스텝 번호
    double total_planning_time_ms;          // 총 경로 계획 시간
    double last_planning_time_ms;           // 마지막 스텝의 경로 계획 시간
    double max_planning_time_ms;            // 가장 오래 걸린 경로 계획 시간
    unsigned long long tasks_completed_total; // 시뮬레이션 전체에서 완료된 작업 수
    unsigned long long algorithm_operation_count; // 알고리즘 연산 횟수 (WFG 엣지, SCC, CBS 확장 등)
    double total_movement_cost;             // 모든 에이전트의 총 이동 거리
    unsigned long long deadlock_count;      // 교착 상태로 추정되는 스텝 수
    double memory_usage_sum_kb;             // 메모리 사용량 누적 합계 (KB)
    double memory_usage_peak_kb;            // 최대 메모리 사용량 (KB)
    int memory_samples;                     // 메모리 측정 횟수
    // --- 알고리즘 전용 메모리 메트릭 ---
    double algo_mem_sum_kb;                 // 알고리즘 단계 직후 메모리 사용량 누적 합계
    double algo_mem_peak_kb;                // 알고리즘 단계 직후 최대 메모리 사용량
    int algo_mem_samples;                   // 알고리즘 메모리 측정 횟수
    int last_task_completion_step;          // 마지막 작업이 완료된 스텝 번호
    int total_executed_steps;               // 총 실행된 물리적 스텝 수
    unsigned long long last_report_completed_tasks; // 마지막 대시보드 보고 시점의 완료된 작업 수
    int last_report_step;                   // 마지막 대시보드 보고 시점의 스텝
    // --- 작업 완료 기준 집계 메트릭 ---
    unsigned long long metrics_task_count;  // 성능이 측정된 총 작업 수
    double metrics_sum_dmove;               // 작업당 이동 거리 합계
    long long metrics_sum_turns;            // 작업당 회전 수 합계
    double metrics_sum_ttask;               // 작업당 소요 시간(스텝) 합계
    // --- 실시간 모드 요청 메트릭 ---
    unsigned long long requests_created_total; // 총 생성된 요청 수
    unsigned long long request_wait_ticks_sum; // 모든 요청의 총 대기 시간(틱) 합계
    // --- 알고리즘 연산 메트릭 (노드 확장 수, 힙 이동 수) ---
    unsigned long long algo_nodes_expanded_total;     // 총 노드 확장 수
    unsigned long long algo_heap_moves_total;         // 총 힙 이동 수
    unsigned long long algo_nodes_expanded_last_step;  // 마지막 스텝의 노드 확장 수
    unsigned long long algo_heap_moves_last_step;      // 마지막 스텝의 힙 이동 수
    unsigned long long algo_generated_nodes_total;      // candidate nodes accepted this run
    unsigned long long algo_valid_expansions_total;     // successful relaxations this run
    unsigned long long algo_generated_nodes_last_step;  // generated nodes in last step
    unsigned long long algo_valid_expansions_last_step; // valid relaxations in last step
} Simulation;

// MetricsSnapshot 구조체 전방 선언 (옵저버 시그니처용)
typedef struct MetricsSnapshot_ MetricsSnapshot;

// Simulation이 Metrics Observer를 구독하여 섀도우를 동기화 (정의는 MetricsSnapshot 정의 이후)

// --- 메트릭 집계 헬퍼 (작업별 마무리) ---
// 활성화된 작업이 있으면 메트릭을 집계하고 종료
static inline void metrics_finalize_task_if_active(Simulation* sim, Agent* ag) {
    if (!sim || !ag || !ag->metrics_task_active) return;
    int steps_now = (sim->scenario_manager ? sim->scenario_manager->time_step : 0);
    double d_move = ag->total_distance_traveled - ag->metrics_distance_at_start;
    int turns = ag->metrics_turns_current;
    double t_task = (double)(steps_now - ag->metrics_task_start_step);
    if (t_task < 0) t_task = 0;
    sim->metrics_task_count++;
    sim->metrics_sum_dmove += d_move;
    sim->metrics_sum_turns += turns;
    sim->metrics_sum_ttask += t_task;
    ag->metrics_task_active = 0;
    ag->metrics_turns_current = 0;
}

// --- 단순 메트릭 (상태 패널 표시용) ---
static struct {
    int whca_h;
    int wf_edges_last;
    long long wf_edges_sum;
    int scc_last;
    long long scc_sum;
    int cbs_ok_last;
    int cbs_exp_last;
    long long cbs_success_sum;
    long long cbs_fail_sum;
    // --- WHCA* 노드 확장 수 (스텝별 임시 저장용) ---
    unsigned long long whca_nodes_expanded_this_step;
    unsigned long long whca_heap_moves_this_step;
    // --- A* 알고리즘 메트릭 (스텝별 임시 저장용) ---
    unsigned long long astar_nodes_expanded_this_step;
    unsigned long long astar_heap_moves_this_step;
    // --- WHCA* 알고리즘 메트릭 (스텝별 임시 저장용 - D* Lite 부분) ---
    unsigned long long whca_dstar_nodes_expanded_this_step;
    unsigned long long whca_dstar_heap_moves_this_step;
    // --- D* Lite 알고리즘 메트릭 (스텝별 임시 저장용) ---
    unsigned long long dstar_nodes_expanded_this_step;
    unsigned long long dstar_heap_moves_this_step;
    unsigned long long whca_generated_nodes_this_step;
    unsigned long long whca_valid_expansions_this_step;
    unsigned long long whca_dstar_generated_nodes_this_step;
    unsigned long long whca_dstar_valid_expansions_this_step;
    unsigned long long astar_generated_nodes_this_step;
    unsigned long long astar_valid_expansions_this_step;
    unsigned long long dstar_generated_nodes_this_step;
    unsigned long long dstar_valid_expansions_this_step;
} g_metrics = { 0 };

// --- GlobalConfig (non-invasive; mirrors existing globals by pointer) ---
typedef struct {
    int* whca_horizon_ptr;
    char* display_buffer_ptr;
} GlobalConfig;
static GlobalConfig g_config;
static inline void GlobalConfig_init(GlobalConfig* cfg) {
    if (!cfg) return;
    cfg->whca_horizon_ptr = &g_whca_horizon;
    cfg->display_buffer_ptr = g_display_buf;
}

// --- Metrics Observer (publish g_metrics snapshots to observers) ---
typedef struct MetricsSnapshot_ {
    int whca_h;
    int wf_edges_last;
    long long wf_edges_sum;
    int scc_last;
    long long scc_sum;
    int cbs_ok_last;
    int cbs_exp_last;
    long long cbs_success_sum;
    long long cbs_fail_sum;
    int whca_horizon;
} MetricsSnapshot;

typedef void (*MetricsObserverFn)(void* ctx, const MetricsSnapshot* snap);
typedef struct { MetricsObserverFn fn; void* ctx; } MetricsObserver;

#ifndef MAX_METRICS_OBSERVERS
#define MAX_METRICS_OBSERVERS 8
#endif
static MetricsObserver g_metrics_observers[MAX_METRICS_OBSERVERS];
static int g_metrics_observer_count = 0;

static inline MetricsSnapshot metrics_build_snapshot(void) {
    MetricsSnapshot s;
    s.whca_h = g_metrics.whca_h;
    s.wf_edges_last = g_metrics.wf_edges_last;
    s.wf_edges_sum = g_metrics.wf_edges_sum;
    s.scc_last = g_metrics.scc_last;
    s.scc_sum = g_metrics.scc_sum;
    s.cbs_ok_last = g_metrics.cbs_ok_last;
    s.cbs_exp_last = g_metrics.cbs_exp_last;
    s.cbs_success_sum = g_metrics.cbs_success_sum;
    s.cbs_fail_sum = g_metrics.cbs_fail_sum;
    s.whca_horizon = g_whca_horizon;
    return s;
}
static void metrics_subscribe(MetricsObserverFn fn, void* ctx) {
    if (!fn) return;
    if (g_metrics_observer_count >= MAX_METRICS_OBSERVERS) return;
    g_metrics_observers[g_metrics_observer_count++] = (MetricsObserver){ fn, ctx };
}
static void metrics_notify_all(void) {
    MetricsSnapshot snap = metrics_build_snapshot();
    for (int i = 0; i < g_metrics_observer_count; i++) {
        if (g_metrics_observers[i].fn) g_metrics_observers[i].fn(g_metrics_observers[i].ctx, &snap);
    }
}

// Simulation이 Metrics Observer를 구독하여 섀도우를 동기화
static void simulation_metrics_observer(void* ctx, const MetricsSnapshot* s) {
    Simulation* sim = (Simulation*)ctx;
    if (!sim || !s) return;
    sim->whca_horizon_shadow = s->whca_horizon;
    sim->algo_rt_metrics_shadow.whca_h = s->whca_h;
    sim->algo_rt_metrics_shadow.wf_edges_last = s->wf_edges_last;
    sim->algo_rt_metrics_shadow.wf_edges_sum = s->wf_edges_sum;
    sim->algo_rt_metrics_shadow.scc_last = s->scc_last;
    sim->algo_rt_metrics_shadow.scc_sum = s->scc_sum;
    sim->algo_rt_metrics_shadow.cbs_ok_last = s->cbs_ok_last;
    sim->algo_rt_metrics_shadow.cbs_exp_last = s->cbs_exp_last;
    sim->algo_rt_metrics_shadow.cbs_success_sum = s->cbs_success_sum;
    sim->algo_rt_metrics_shadow.cbs_fail_sum = s->cbs_fail_sum;
}

// --- 호라이즌 적응 점수 ---
static int g_conflict_score = 0;

// --- 렌더러 (객체 지향: 렌더링 관련 전역 변수를 구조체로 래핑) ---
typedef struct {
    int render_stride;
    int fast_render;
    int simple_colors;
} Renderer;

static Renderer g_renderer = { 1, 0, 0 };

// =============================================================================
// 섹션 3: 함수 프로토타입
// =============================================================================
// --- API 호환성 별칭 (비파괴적) ---
#define grid_map_create Grid_create
#define grid_map_destroy Grid_destroy
#define grid_is_valid_coord Grid_isValidCoord
#define grid_is_node_blocked Grid_isNodeBlocked

void ensure_console_width(int minCols);

Simulation* simulation_create();
void simulation_destroy(Simulation* sim);
void simulation_run(Simulation* sim);
void simulation_print_performance_summary(const Simulation* sim);
static void simulation_report_realtime_dashboard(Simulation* sim);
static void simulation_collect_memory_sample(Simulation* sim);
static void simulation_collect_memory_sample_algo(Simulation* sim);
static void simulation_reset_runtime_stats(Simulation* sim);
// UI helpers (unified naming)
static void ui_append_controls_help(char** p, size_t* rem);
static void ui_flush_display_buffer(void);
// Control/Plan helpers (unified naming)
static void ui_handle_control_key(Simulation* sim, int ch, int* is_paused, int* quit_flag);
static void simulation_plan_step(Simulation* sim, Node* next_pos[MAX_AGENTS]);
static int apply_moves_and_update_stuck(Simulation* sim, Node* next_pos[MAX_AGENTS], Node* prev_pos[MAX_AGENTS]);
static void update_deadlock_counter(Simulation* sim, int moved_this_step, int is_custom_mode);
static void accumulate_wait_ticks_if_realtime(Simulation* sim);
static void maybe_report_realtime_dashboard(Simulation* sim);
// Planner strategy helper
static Planner planner_from_pathalgo(PathAlgo algo);
// Renderer facade helper
static RendererFacade renderer_create_facade(void);
// One-step execution helper (encapsulate one simulation tick)
static void simulation_execute_one_step(Simulation* sim, int is_paused);
// Cleanup helper
static void force_idle_cleanup(AgentManager* am, Simulation* sim, Logger* lg);
// Agent/AgentManager OO-like wrappers
void agent_begin_task_park(Agent* ag, ScenarioManager* sc, Logger* lg);
void agent_begin_task_exit(Agent* ag, ScenarioManager* sc, Logger* lg);

void system_enable_virtual_terminal();
void ui_clear_screen_optimized();

int simulation_setup(Simulation* sim);

// ★ Map selection
static int simulation_setup_map(Simulation* sim);
void grid_map_load_scenario(GridMap* map, AgentManager* am, int scenario_id);
// --- Procedural map builders (for Map #2 ~ #5)
static void map_build_hypermart(GridMap* m, AgentManager* am);       // #2
static void map_build_10agents_200slots(GridMap* m, AgentManager* am); // #3
static void map_build_biggrid_onegoal(GridMap* m, AgentManager* am); // #4
static void map_build_cross_4agents(GridMap* m, AgentManager* am);   // #5 Cross map

// Common helpers
static void grid_map_clear(GridMap* map);
static void map_all_free(GridMap* m);
static void map_add_border_walls(GridMap* m);
static void map_place_goal(GridMap* m, int x, int y);
static void map_place_charge(GridMap* m, int x, int y);
static void map_place_agent_at(AgentManager* am, GridMap* m, int idx, int x, int y);
static void map_reserve_area_as_start(GridMap* m, int x0, int y0, int w, int h); // 비우기



// Logger
void logger_log(Logger* logger, const char* format, ...);
Logger* logger_create();
void logger_destroy(Logger*);

// Grid
GridMap* grid_map_create(AgentManager*);
void grid_map_destroy(GridMap*);
int grid_is_valid_coord(int x, int y);
int grid_is_node_blocked(const GridMap*, const AgentManager*, const Node*, const struct Agent_*);

// Scenario
ScenarioManager* scenario_manager_create();
void scenario_manager_destroy(ScenarioManager*);

// Agents
AgentManager* agent_manager_create();
void agent_manager_destroy(AgentManager*);
void agent_manager_plan_and_resolve_collisions(AgentManager*, GridMap*, Logger*, Node* next_pos[MAX_AGENTS]);
void agent_manager_update_state_after_move(AgentManager*, ScenarioManager*, GridMap*, Logger*, Simulation*);
void agent_manager_update_charge_state(AgentManager*, GridMap*, Logger*);

// Alternate planners (for algorithm selection)
void agent_manager_plan_and_resolve_collisions_astar(AgentManager*, GridMap*, Logger*, Node* next_pos[MAX_AGENTS]);
void agent_manager_plan_and_resolve_collisions_dstar_basic(AgentManager*, GridMap*, Logger*, Node* next_pos[MAX_AGENTS]);

// Pathfinder (Incremental D* Lite)
Pathfinder* pathfinder_create(Node* start, Node* goal, const struct Agent_* agent);
void pathfinder_destroy(Pathfinder* pf);
void pathfinder_reset_goal(Pathfinder* pf, Node* new_goal);
void pathfinder_update_start(Pathfinder* pf, Node* new_start);
void pathfinder_notify_cell_change(Pathfinder* pf, GridMap* map, const AgentManager* am, Node* changed);
void pathfinder_compute_shortest_path(Pathfinder* pf, GridMap* map, const AgentManager* am);
Node* pathfinder_get_next_step(Pathfinder* pf, const GridMap* map, const AgentManager* am, Node* current_node);

// WFG + CBS helpers
static void add_wait_edge(WaitEdge* edges, int* cnt, int from, int to, int t, CauseType cause, int x1, int y1, int x2, int y2);
static int  build_scc_mask_from_edges(const WaitEdge* edges, int cnt);
static int  run_partial_CBS(AgentManager* m, GridMap* map, Logger* lg,
    int group_ids[], int group_n, const ReservationTable* base_rt,
    Node* out_plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1]);

// D* Lite 통지 브로드캐스트
static void broadcast_cell_change(AgentManager* am, GridMap* map, Node* changed);

// 호라이즌 자동조정
static void WHCA_adjustHorizon(int wf_edges, int scc, Logger* lg);

// 입력 도움
static char get_single_char();
static char get_char_input(const char* prompt, const char* valid);
static int  get_integer_input(const char* prompt, int min, int max);
static float get_float_input(const char* prompt, float min, float max);
// *** NEW *** Non-blocking input check
static int check_for_input();

// --- PathfinderFactory: 경로파인더 생성/파괴 통일 ---
typedef struct PathfinderFactory_ {
    Pathfinder* (*create)(Node* start, Node* goal);
    void (*destroy)(Pathfinder* pf);
} PathfinderFactory;
static inline Pathfinder* pf_factory_create(Node* start, Node* goal) { return pathfinder_create(start, goal, NULL); }
static inline void pf_factory_destroy(Pathfinder* pf) { pathfinder_destroy(pf); }
static PathfinderFactory g_pf_factory = { pf_factory_create, pf_factory_destroy };

// 공통 충돌 해소 전방 선언
static void resolve_conflicts_by_order(const AgentManager* m, const int order[MAX_AGENTS], Node* next_pos[MAX_AGENTS]);


// =============================================================================
// 섹션 4: 시스템, 입출력 및 헬퍼 함수
// =============================================================================
// --- D* Lite 통지를 포함한 임시 마킹 정리 (증분 탐색 일관성 유지) ---
/**
 * @brief l->nodes에 기록된 모든 임시 장애물 마킹을 해제하고,
 *        D* Lite 경로 탐색기에 환경 변화(셀 비용 변경)를 통지합니다.
 * @param l 임시 마킹된 노드 목록
 * @param pf 변경을 통지할 Pathfinder 인스턴스
 * @param map 그리드 맵
 * @param am 에이전트 관리자
 */
static inline void temp_unmark_all_and_notify(TempMarkList* l, Pathfinder* pf, GridMap* map, const AgentManager* am) {
    if (!l) return;
    for (int i = 0; i < l->count; i++) {
        Node* n = l->nodes[i];
        if (!n) continue;
        n->is_temp = FALSE;
        if (pf) pathfinder_notify_cell_change(pf, map, am, n);
    }
    l->count = 0;
}
// --- 통합 임시 마킹 컨텍스트 (D* Lite 자동 통지 옵션 포함) ---
typedef struct {
    TempMarkList marks;     // 임시 마킹된 노드 목록
    Pathfinder* pf;         // (선택) 자동 통지 활성화 시 사용될 Pathfinder
    GridMap* map;           // (자동 통지 시 필수) 그리드 맵
    AgentManager* am;       // (자동 통지 시 필수) 에이전트 관리자
    int auto_notify;        // 0: 마킹 해제만, 1: 해제 + D* Lite 통지
} TempMarkContext;

/**
 * @brief 임시 마킹 컨텍스트를 초기화합니다.
 * @param ctx 초기화할 컨텍스트 포인터
 * @param pf (선택) 자동 통지에 사용할 Pathfinder
 * @param map (자동 통지 시 필수) 그리드 맵
 * @param am (자동 통지 시 필수) 에이전트 관리자
 * @param auto_notify 자동 통지 활성화 여부
 */
static inline void temp_context_init(TempMarkContext* ctx, Pathfinder* pf, GridMap* map, AgentManager* am, int auto_notify) {
    if (!ctx) return;
    temp_mark_init(&ctx->marks);
    ctx->pf = pf;
    ctx->map = map;
    ctx->am = am;
    ctx->auto_notify = auto_notify;
}

/**
 * @brief 컨텍스트를 통해 노드를 임시 장애물로 마킹합니다.
 *        auto_notify가 활성화된 경우, D* Lite에 즉시 변경 사항을 통지합니다.
 * @param ctx 임시 마킹 컨텍스트
 * @param n 마킹할 노드
 */
static inline void temp_context_mark(TempMarkContext* ctx, Node* n) {
    if (!ctx || !n) return;
    temp_mark_node(&ctx->marks, n);
    if (ctx->auto_notify && ctx->pf) {
        pathfinder_notify_cell_change(ctx->pf, ctx->map, ctx->am, n);
    }
}

/**
 * @brief 컨텍스트에 기록된 모든 임시 마킹을 해제합니다.
 *        auto_notify 설정에 따라 D* Lite 통지 여부가 결정됩니다.
 * @param ctx 정리할 컨텍스트
 */
static inline void temp_context_cleanup(TempMarkContext* ctx) {
    if (!ctx) return;
    if (ctx->auto_notify) temp_unmark_all_and_notify(&ctx->marks, ctx->pf, ctx->map, ctx->am);
    else temp_unmark_all(&ctx->marks);
}
/**
 * @brief Windows 콘솔에서 가상 터미널(ANSI 이스케이프 시퀀스) 처리를 활성화합니다.
 *        이를 통해 색상 코드, 커서 이동 등 다양한 터미널 제어가 가능해집니다.
 */
void system_enable_virtual_terminal() {
    HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hOut == INVALID_HANDLE_VALUE) return;
    DWORD dwMode = 0;
    if (!GetConsoleMode(hOut, &dwMode)) return;
    dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    SetConsoleMode(hOut, dwMode);
}

/**
 * @brief 화면을 지웁니다. 가상 터미널 지원 여부에 따라 최적화된 방식을 사용합니다.
 *        - 지원 시: ANSI 이스케이프 시퀀스(\\x1b[2J)를 사용하여 화면과 스크롤백 버퍼를 모두 지웁니다.
 *        - 미지원 시: 기존 Windows API를 사용하여 화면 버퍼 전체를 공백으로 채웁니다.
 */
void ui_clear_screen_optimized() {
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsole == INVALID_HANDLE_VALUE) return;

    DWORD mode = 0;
    if (GetConsoleMode(hConsole, &mode) && (mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING)) {
        // VT(ANSI) 지원됨: 화면+스크롤백 모두 지우고 커서 홈
        fputs("\x1b[H\x1b[2J\x1b[3J", stdout);
        fflush(stdout);
        return;
    }

    // (레거시 CMD 등) VT 미지원: 기존 Win32 방식으로 버퍼 전체 지우기
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(hConsole, &csbi)) return;

    DWORD cellCount = (DWORD)csbi.dwSize.X * (DWORD)csbi.dwSize.Y;
    DWORD count;
    COORD home = { 0, 0 };

    FillConsoleOutputCharacterA(hConsole, ' ', cellCount, home, &count);
    FillConsoleOutputAttribute(hConsole, csbi.wAttributes, cellCount, home, &count);
    SetConsoleCursorPosition(hConsole, home);
}

/**
 * @brief 콘솔 창의 너비가 최소 너비(minCols)보다 작을 경우, 버퍼 크기를 조정하여
 *        줄 바꿈 현상을 방지하고 UI가 깨지지 않도록 합니다.
 * @param minCols 필요한 최소 콘솔 너비
 */
void ensure_console_width(int minCols) {
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    if (h == INVALID_HANDLE_VALUE) return;

    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(h, &csbi)) return;

    COORD size = csbi.dwSize;
    if (size.X < minCols) {
        size.X = (SHORT)minCols;
        // 버퍼 폭을 먼저 키워주면 창 크기 변동 없이 줄감김이 줄어듭니다.
        SetConsoleScreenBufferSize(h, size);
    }
}

/**
 * @brief 현재 프로세스의 메모리 사용량(Working Set)을 측정하여 Simulation 구조체에 기록합니다.
 * @param sim 메모리 사용량 데이터를 저장할 Simulation 인스턴스
 */
static void simulation_collect_memory_sample(Simulation* sim) {
#ifdef _WIN32
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
        double working_set_kb = (double)pmc.WorkingSetSize / 1024.0;
        sim->memory_usage_sum_kb += working_set_kb;
        if (working_set_kb > sim->memory_usage_peak_kb) sim->memory_usage_peak_kb = working_set_kb;
        sim->memory_samples++;
    }
#else
    (void)sim;
#endif
}

/**
 * @brief 알고리즘 실행 직후의 메모리 사용량을 측정합니다.
 *        이는 렌더링, 로그 출력 등 다른 요소의 영향을 최소화하고
 *        순수 알고리즘의 메모리 사용량을 추정하기 위함입니다.
 * @param sim 메모리 사용량 데이터를 저장할 Simulation 인스턴스
 */
static void simulation_collect_memory_sample_algo(Simulation* sim) {
#ifdef _WIN32
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
        double working_set_kb = (double)pmc.WorkingSetSize / 1024.0;
        sim->algo_mem_sum_kb += working_set_kb;
        if (working_set_kb > sim->algo_mem_peak_kb) sim->algo_mem_peak_kb = working_set_kb;
        sim->algo_mem_samples++;
    }
#else
    (void)sim;
#endif
}

/**
 * @brief 시뮬레이션의 런타임 통계 데이터(CPU 시간, 메모리 사용량, 작업 수 등)를 모두 초기화합니다.
 *        새로운 시뮬레이션 실행 전에 호출됩니다.
 * @param sim 초기화할 Simulation 인스턴스
 */
static void simulation_reset_runtime_stats(Simulation* sim) {
    if (!sim) return;
    sim->total_cpu_time_ms = 0.0;
    sim->last_step_cpu_time_ms = 0.0;
    sim->max_step_cpu_time_ms = 0.0;
    memset(sim->phase_cpu_time_ms, 0, sizeof(sim->phase_cpu_time_ms));
    memset(sim->phase_step_counts, 0, sizeof(sim->phase_step_counts));
    memset(sim->phase_completed_tasks, 0, sizeof(sim->phase_completed_tasks));
    for (int i = 0; i < MAX_PHASES; i++) {
        sim->phase_first_step[i] = -1;
        sim->phase_last_step[i] = -1;
    }
    sim->post_phase_cpu_time_ms = 0.0;
    sim->post_phase_step_count = 0;
    sim->post_phase_first_step = -1;
    sim->post_phase_last_step = -1;
    sim->total_planning_time_ms = 0.0;
    sim->last_planning_time_ms = 0.0;
    sim->max_planning_time_ms = 0.0;
    sim->tasks_completed_total = 0;
    sim->algorithm_operation_count = 0;
    sim->total_movement_cost = 0.0;
    sim->deadlock_count = 0;
    sim->memory_usage_sum_kb = 0.0;
    sim->memory_usage_peak_kb = 0.0;
    sim->memory_samples = 0;
    sim->algo_mem_sum_kb = 0.0;
    sim->algo_mem_peak_kb = 0.0;
    sim->algo_mem_samples = 0;
    sim->last_task_completion_step = 0;
    sim->total_executed_steps = 0;
    sim->last_report_completed_tasks = 0;
    sim->last_report_step = 0;
    sim->metrics_task_count = 0;
    sim->metrics_sum_dmove = 0.0;
    sim->metrics_sum_turns = 0;
    sim->metrics_sum_ttask = 0.0;
    sim->requests_created_total = 0;
    sim->request_wait_ticks_sum = 0;
    sim->algo_generated_nodes_total = 0;
    sim->algo_valid_expansions_total = 0;
    sim->algo_generated_nodes_last_step = 0;
    sim->algo_valid_expansions_last_step = 0;
}

/**
 * @brief 실시간 모드에서 주기적으로 현재 시뮬레이션 상태 대시보드를 콘솔에 출력합니다.
 * @param sim 대시보드 정보를 가져올 Simulation 인스턴스
 */
static void simulation_report_realtime_dashboard(Simulation* sim) {
    ScenarioManager* sc = sim->scenario_manager;
    int steps = (sim->total_executed_steps > 0) ? sim->total_executed_steps : (sc ? sc->time_step : 0);
    if (steps <= 0) steps = 1;

    unsigned long long total_completed = sim->tasks_completed_total;
    int interval_steps = steps - sim->last_report_step;
    if (interval_steps <= 0) interval_steps = 1;
    unsigned long long delta_completed = total_completed - sim->last_report_completed_tasks;

    double throughput_avg = (double)total_completed / (double)steps;
    double throughput_interval = (double)delta_completed / (double)interval_steps;
    double avg_planning_ms = (steps > 0) ? sim->total_planning_time_ms / (double)steps : 0.0;
    double avg_memory_kb = (sim->memory_samples > 0) ? sim->memory_usage_sum_kb / (double)sim->memory_samples : 0.0;

    int active_agents = 0;
    if (sim->agent_manager) {
        for (int i = 0; i < MAX_AGENTS; i++) {
            if (sim->agent_manager->agents[i].pos) active_agents++;
        }
    }

    printf("\n========== Real-Time Dashboard @ step %d ==========\n", steps);
    printf(" Total Physical Time Steps      : %d\n", steps);
    printf(" Operating AGVs                 : %d\n", active_agents);
    printf(" Tasks Completed (total)        : %llu\n", total_completed);
    printf(" Throughput (total avg)         : %.4f tasks/step\n", throughput_avg);
    printf(" Throughput (last interval)     : %.4f tasks/step over %d steps\n", throughput_interval, interval_steps);
    printf(" Total Computation CPU Time     : %.2f ms\n", sim->total_cpu_time_ms);
    printf(" Average Planning Time / Step   : %.4f ms\n", avg_planning_ms);
    printf(" Total Task Completion Step     : %d\n", sim->last_task_completion_step);
    printf(" Total Movement Cost            : %.2f cells\n", sim->total_movement_cost);
    printf(" Requests Created (total)       : %llu\n", sim->requests_created_total);
    printf(" Request Wait Ticks (sum)       : %llu\n", sim->request_wait_ticks_sum);
    printf(" Process Memory Usage Sum      : %.2f KB (avg %.2f KB / sample, peak %.2f KB)\n",
        sim->memory_usage_sum_kb, avg_memory_kb, sim->memory_usage_peak_kb);
    printf(" Heap Moves (total/last)          : %llu / %llu\n", sim->algo_heap_moves_total, sim->algo_heap_moves_last_step);
    printf(" Generated Nodes (total/last)     : %llu / %llu\n", sim->algo_generated_nodes_total, sim->algo_generated_nodes_last_step);
    printf(" Valid Expansions (total/last)    : %llu / %llu\n", sim->algo_valid_expansions_total, sim->algo_valid_expansions_last_step);
    double dash_ratio_total = (sim->algo_generated_nodes_total > 0) ? (double)sim->algo_valid_expansions_total / (double)sim->algo_generated_nodes_total : 0.0;
    double dash_ratio_last = (sim->algo_generated_nodes_last_step > 0) ? (double)sim->algo_valid_expansions_last_step / (double)sim->algo_generated_nodes_last_step : 0.0;
    printf(" Valid Expansion Ratio (total/last): %.4f / %.4f\n", dash_ratio_total, dash_ratio_last);
    printf("===================================================\n");

    sim->last_report_completed_tasks = total_completed;
    sim->last_report_step = steps;
}


/**
 * @brief 키보드 입력이 있는지 비동기적으로 확인합니다.
 * @return 입력이 있으면 해당 키의 ASCII 코드를, 없으면 0을 반환합니다.
 */
static int check_for_input() {
    if (_kbhit()) {
        return _getch();
    }
    return 0;
}

// --- 제어 상태 캡슐화 ---
typedef struct {
    int is_paused;  // 일시정지 여부
    int quit_flag;  // 종료 플래그
    int last_key;   // 마지막으로 입력된 키
} ControlState;
/**
 * @brief ControlState 구조체를 기본값으로 초기화합니다.
 * @param cs 초기화할 ControlState 포인터
 */
static inline void ControlState_init(ControlState* cs) {
    if (!cs) return;
    cs->is_paused = FALSE;
    cs->quit_flag = FALSE;
    cs->last_key = 0;
}

/**
 * @brief 콘솔에서 단일 문자를 입력받습니다. (에코 없음)
 * @return 입력된 문자의 ASCII 코드
 */
static char get_single_char() {
    return _getch();
}

/**
 * @brief 사용자에게 프롬프트를 표시하고, 유효한 문자 집합(valid) 중 하나를 입력받을 때까지 반복합니다.
 * @param prompt 사용자에게 보여줄 안내 메시지
 * @param valid 입력 가능한 유효한 문자들로 이루어진 문자열
 * @return 사용자가 입력한 유효한 문자 (소문자로 변환됨)
 */
static char get_char_input(const char* prompt, const char* valid) {
    char c;
    while (TRUE) {
        printf("%s", prompt);
        c = (char)tolower(get_single_char());
        printf("%c\n", c);
        if (strchr(valid, c)) return c;
        printf(C_B_RED "\n잘못된 입력입니다. (%s)\n" C_NRM, valid);
    }
}

/**
 * @brief 사용자에게 프롬프트를 표시하고, 지정된 범위 [min, max] 내의 정수를 입력받습니다.
 * @param prompt 사용자에게 보여줄 안내 메시지
 * @param min 입력 가능한 최소 정수값
 * @param max 입력 가능한 최대 정수값
 * @return 사용자가 입력한 유효한 정수
 */
static int get_integer_input(const char* prompt, int min, int max) {
    char buf[INPUT_BUFFER_SIZE];
    int v;
    while (TRUE) {
        printf("%s", prompt);
        if (fgets(buf, sizeof(buf), stdin) && sscanf(buf, "%d", &v) == 1 && v >= min && v <= max) return v;
        printf(C_B_RED "잘못된 입력입니다. %d~%d 정수.\n" C_NRM, min, max);
    }
}

/**
 * @brief 사용자에게 프롬프트를 표시하고, 지정된 범위 [min, max] 내의 실수를 입력받습니다.
 * @param prompt 사용자에게 보여줄 안내 메시지
 * @param min 입력 가능한 최소 실수값
 * @param max 입력 가능한 최대 실수값
 * @return 사용자가 입력한 유효한 실수
 */
static float get_float_input(const char* prompt, float min, float max) {
    char buf[INPUT_BUFFER_SIZE];
    float v;
    while (TRUE) {
        printf("%s", prompt);
        if (fgets(buf, sizeof(buf), stdin) && sscanf(buf, "%f", &v) == 1 && v >= min && v <= max) return v;
        printf(C_B_RED "잘못된 입력입니다. %.1f~%.1f.\n" C_NRM, min, max);
    }
}

// ---- UI / Render ----
void ui_enter_alt_screen(void) {
    // ALT buffer + 홈 + 커서 숨김
    fputs("\x1b[?1049h\x1b[H\x1b[?25l", stdout);
    fflush(stdout);
}
void ui_leave_alt_screen(void) {
    // ALT buffer 해제 + 커서 보이기
    fputs("\x1b[?1049l\x1b[?25h", stdout);
    fflush(stdout);
}

static void ui_append_controls_help(char** p, size_t* rem) {
    APPEND_FMT(*p, *rem, "%s--- Controls ---%s\n", C_B_WHT, C_NRM);
    APPEND_FMT(*p, *rem, "[%sP%s]ause/Resume | [%sS%s]tep | [%s+%s]/[%s-%s] Speed | ",
        C_YEL, C_NRM, C_YEL, C_NRM, C_YEL, C_NRM, C_YEL, C_NRM);
    APPEND_FMT(*p, *rem, "[%s[%s]/[%s]%s Render stride | ", C_YEL, C_NRM, C_YEL, C_NRM);
    APPEND_FMT(*p, *rem, "[%sF%s]ast render | [%sC%s]olor simple | [%sQ%s]uit\n",
        C_YEL, C_NRM, C_YEL, C_NRM, C_YEL, C_NRM);
}

static void ui_flush_display_buffer(void) {
    size_t cur_len = strlen(g_display_buf);
    if (!g_renderer.fast_render) ui_clear_screen_optimized(); else fputs("\x1b[H", stdout);
    fwrite(g_display_buf, 1, cur_len, stdout);
    fflush(stdout);
}

/**
 * @brief 사용자의 키 입력을 받아 시뮬레이션 상태(일시정지, 속도, 종료 등)를 변경합니다.
 * @param sim 제어할 Simulation 인스턴스
 * @param ch 사용자가 입력한 키 문자
 * @param is_paused 일시정지 상태 플래그 포인터
 * @param quit_flag 종료 플래그 포인터
 */
static void ui_handle_control_key(Simulation* sim, int ch, int* is_paused, int* quit_flag) {
    switch (tolower(ch)) {
    case 'p':
        *is_paused = !*is_paused;
        logger_log(sim->logger, *is_paused ? "[CTRL] Simulation Paused." : "[CTRL] Simulation Resumed.");
        break;
    case 's':
        if (*is_paused) {
            logger_log(sim->logger, "[CTRL] Advancing one step.");
        }
        break;
    case '+':
    case '=':
        sim->scenario_manager->speed_multiplier += 0.5f;
        if (sim->scenario_manager->speed_multiplier > MAX_SPEED_MULTIPLIER)
            sim->scenario_manager->speed_multiplier = MAX_SPEED_MULTIPLIER;
        logger_log(sim->logger, "[CTRL] Speed increased to %.1fx", sim->scenario_manager->speed_multiplier);
        break;
    case '-':
        sim->scenario_manager->speed_multiplier -= 0.5f;
        if (sim->scenario_manager->speed_multiplier < 0.1f)
            sim->scenario_manager->speed_multiplier = 0.1f;
        logger_log(sim->logger, "[CTRL] Speed decreased to %.1fx", sim->scenario_manager->speed_multiplier);
        break;
    case 'q':
        *quit_flag = TRUE;
        logger_log(sim->logger, "[CTRL] Quit simulation.");
        break;
    case ']':
        if (g_renderer.render_stride < RENDER_STRIDE_MAX) g_renderer.render_stride <<= 1;
        if (g_renderer.render_stride < RENDER_STRIDE_MIN) g_renderer.render_stride = RENDER_STRIDE_MIN;
        logger_log(sim->logger, "[CTRL] Render stride = %d", g_renderer.render_stride);
        break;
    case '[':
        if (g_renderer.render_stride > RENDER_STRIDE_MIN) g_renderer.render_stride >>= 1;
        logger_log(sim->logger, "[CTRL] Render stride = %d", g_renderer.render_stride);
        break;
    case 'f':
        g_renderer.fast_render = !g_renderer.fast_render;
        logger_log(sim->logger, g_renderer.fast_render ? "[CTRL] Fast render ON" : "[CTRL] Fast render OFF");
        break;
    case 'c':
        g_renderer.simple_colors = !g_renderer.simple_colors;
        logger_log(sim->logger, g_renderer.simple_colors ? "[CTRL] Simple colors ON" : "[CTRL] Simple colors OFF");
        break;
    }

    // 속도 변경 시 sleep 시간 재계산
    if (ch == '+' || ch == '=' || ch == '-') {
        sim->scenario_manager->simulation_speed = (int)(100.0f / sim->scenario_manager->speed_multiplier);
        if (sim->scenario_manager->simulation_speed < 0) sim->scenario_manager->simulation_speed = 0;
    }
}

/**
 * @brief 현재 선택된 경로 계획 알고리즘에 따라 에이전트들의 다음 스텝을 계획합니다.
 *        계획에 소요된 CPU 시간을 측정하여 Simulation 통계에 기록합니다.
 * @param sim 시뮬레이션 인스턴스
 * @param next_pos 각 에이전트의 다음 위치를 저장할 배열
 */
static void simulation_plan_step(Simulation* sim, Node* next_pos[MAX_AGENTS]) {
    clock_t plan_start_cpu = clock();

    // 메트릭 초기화 (스텝 시작 시 모든 Pathfinder 메트릭도 초기화)
    sim->algo_nodes_expanded_last_step = 0;
    sim->algo_heap_moves_last_step = 0;
    sim->algo_generated_nodes_last_step = 0;
    sim->algo_valid_expansions_last_step = 0;
    g_metrics.whca_nodes_expanded_this_step = 0;  // WHCA* (Partial CBS) 노드 확장 수 초기화
    g_metrics.whca_heap_moves_this_step = 0;        // WHCA* heap operations reset
    g_metrics.whca_dstar_nodes_expanded_this_step = 0;  // WHCA* (D* Lite 부분) 노드 확장 수 초기화
    g_metrics.whca_dstar_heap_moves_this_step = 0;      // WHCA* (D* Lite 부분) 힙 이동 수 초기화
    g_metrics.astar_nodes_expanded_this_step = 0;  // A* 노드 확장 수 초기화
    g_metrics.astar_heap_moves_this_step = 0;      // A* 힙 이동 수 초기화
    g_metrics.dstar_nodes_expanded_this_step = 0;  // D* Lite 노드 확장 수 초기화
    g_metrics.dstar_heap_moves_this_step = 0;      // D* Lite 힙 이동 수 초기화

    g_metrics.whca_generated_nodes_this_step = 0;
    g_metrics.whca_valid_expansions_this_step = 0;
    g_metrics.whca_dstar_generated_nodes_this_step = 0;
    g_metrics.whca_dstar_valid_expansions_this_step = 0;

    g_metrics.astar_generated_nodes_this_step = 0;
    g_metrics.astar_valid_expansions_this_step = 0;

    g_metrics.dstar_generated_nodes_this_step = 0;
    g_metrics.dstar_valid_expansions_this_step = 0;

    // 각 에이전트의 Pathfinder 메트릭도 초기화 (이전 스텝 값이 남아있을 수 있음)
    if (sim->agent_manager) {
        for (int i = 0; i < MAX_AGENTS; i++) {
            Agent* ag = &sim->agent_manager->agents[i];
            if (ag->pf) {
                ag->pf->nodes_expanded_this_call = 0;
                ag->pf->heap_moves_this_call = 0;
                ag->pf->nodes_generated_this_call = 0;
                ag->pf->valid_expansions_this_call = 0;
            }
        }
    }

    if (sim->planner.vtbl.plan_step) {
        sim->planner.vtbl.plan_step(sim->agent_manager, sim->map, sim->logger, next_pos);
    }
    else {
        switch (sim->path_algo) {
        case PATHALGO_ASTAR_SIMPLE:
            agent_manager_plan_and_resolve_collisions_astar(sim->agent_manager, sim->map, sim->logger, next_pos);
            break;
        case PATHALGO_DSTAR_BASIC:
            agent_manager_plan_and_resolve_collisions_dstar_basic(sim->agent_manager, sim->map, sim->logger, next_pos);
            break;
        case PATHALGO_DEFAULT:
        default:
            agent_manager_plan_and_resolve_collisions(sim->agent_manager, sim->map, sim->logger, next_pos);
            break;
        }
    }

    // 알고리즘 메트릭 수집 (모든 알고리즘이 전역 변수에서 수집하도록 통일)
    unsigned long long step_nodes = 0;
    unsigned long long step_heap_moves = 0;
    unsigned long long step_generated_nodes = 0;
    unsigned long long step_valid_expansions = 0;

    if (sim->path_algo == PATHALGO_ASTAR_SIMPLE) {
        // 2(A*)
        step_nodes = g_metrics.astar_nodes_expanded_this_step;
        step_heap_moves = g_metrics.astar_heap_moves_this_step;
        step_generated_nodes = g_metrics.astar_generated_nodes_this_step;
        step_valid_expansions = g_metrics.astar_valid_expansions_this_step;
    }
    else if (sim->path_algo == PATHALGO_DSTAR_BASIC) {
        // 3 (D* Lite)
        step_nodes = g_metrics.dstar_nodes_expanded_this_step;
        step_heap_moves = g_metrics.dstar_heap_moves_this_step;
        step_generated_nodes = g_metrics.dstar_generated_nodes_this_step;
        step_valid_expansions = g_metrics.dstar_valid_expansions_this_step;
    }
    else {
        // 1(WHCA*)
        // WHCA* D* Lite  + Partial CBS (WHCA*) 
        step_nodes = g_metrics.whca_dstar_nodes_expanded_this_step + g_metrics.whca_nodes_expanded_this_step;
        step_heap_moves = g_metrics.whca_dstar_heap_moves_this_step + g_metrics.whca_heap_moves_this_step;
        step_generated_nodes = g_metrics.whca_dstar_generated_nodes_this_step + g_metrics.whca_generated_nodes_this_step;
        step_valid_expansions = g_metrics.whca_dstar_valid_expansions_this_step + g_metrics.whca_valid_expansions_this_step;
    }

    sim->algo_nodes_expanded_last_step = step_nodes;
    sim->algo_heap_moves_last_step = step_heap_moves;
    sim->algo_generated_nodes_last_step = step_generated_nodes;
    sim->algo_valid_expansions_last_step = step_valid_expansions;
    sim->algo_nodes_expanded_total += step_nodes;
    sim->algo_heap_moves_total += step_heap_moves;
    sim->algo_generated_nodes_total += step_generated_nodes;
    sim->algo_valid_expansions_total += step_valid_expansions;

    clock_t plan_end_cpu = clock();
    double planning_time_ms = ((double)(plan_end_cpu - plan_start_cpu) * 1000.0) / CLOCKS_PER_SEC;
    sim->last_planning_time_ms = planning_time_ms;
    sim->total_planning_time_ms += planning_time_ms;
    if (planning_time_ms > sim->max_planning_time_ms) sim->max_planning_time_ms = planning_time_ms;
    sim->algorithm_operation_count += (unsigned long long)((g_metrics.wf_edges_last > 0 ? g_metrics.wf_edges_last : 0) +
        (g_metrics.scc_last > 0 ? g_metrics.scc_last : 0) +
        (g_metrics.cbs_exp_last > 0 ? g_metrics.cbs_exp_last : 0));
    // 메트릭 변경 알림 (Observer 경유)
    metrics_notify_all();
}

/**
 * @brief 계획된 다음 위치(next_pos)를 에이전트에 적용하고, 이동 여부를 확인합니다.
 *        이동하지 않은 에이전트의 'stuck_steps' 카운터를 증가시킵니다.
 * @param sim 시뮬레이션 인스턴스
 * @param next_pos 각 에이전트의 계획된 다음 위치 배열
 * @param prev_pos 각 에이전트의 이전 위치 배열
 * @return 한 명 이상의 에이전트가 이동했으면 1, 아니면 0을 반환합니다.
 */
static int apply_moves_and_update_stuck(Simulation* sim, Node* next_pos[MAX_AGENTS], Node* prev_pos[MAX_AGENTS]) {
    int moved_this_step = 0;
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &sim->agent_manager->agents[i];
        if (ag->state != CHARGING && next_pos[i]) {
            if (ag->pos != next_pos[i]) {
                ag->total_distance_traveled += 1.0;
                sim->total_movement_cost += 1.0;
                moved_this_step = 1;
            }
            ag->pos = next_pos[i];
        }
    }

    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &sim->agent_manager->agents[i];
        if (ag->state == CHARGING || ag->state == IDLE || ag->action_timer > 0) { ag->stuck_steps = 0; continue; }
        if (ag->pos == prev_pos[i]) ag->stuck_steps++;
        else ag->stuck_steps = 0;
    }

    return moved_this_step;
}

/**
 * @brief 이번 스텝에서 아무도 움직이지 않았고 해결해야 할 작업이 남아있는 경우,
 *        교착 상태(deadlock) 카운터를 증가시킵니다.
 * @param sim 시뮬레이션 인스턴스
 * @param moved_this_step 이번 스텝에서 이동한 에이전트가 있었는지 여부
 * @param is_custom_mode 현재 시나리오가 사용자 정의 모드인지 여부
 */
static void update_deadlock_counter(Simulation* sim, int moved_this_step, int is_custom_mode) {
    ScenarioManager* sc = sim->scenario_manager;
    if (moved_this_step) return;
    int unresolved = 0;
    if (is_custom_mode) {
        if (sc->current_phase_index < sc->num_phases) {
            const DynamicPhase* ph = &sc->phases[sc->current_phase_index];
            if (sc->tasks_completed_in_phase < ph->task_count) unresolved = 1;
        }
    }
    else if (sc->mode == MODE_REALTIME) {
        if (sc->task_count > 0) unresolved = 1;
    }
    if (unresolved) sim->deadlock_count++;
}

/**
 * @brief 실시간 모드에서 대기열에 작업이 있는 경우, 모든 작업의 총 대기 시간을 누적합니다.
 * @param sim 시뮬레이션 인스턴스
 */
static void accumulate_wait_ticks_if_realtime(Simulation* sim) {
    ScenarioManager* sc = sim->scenario_manager;
    if (sc->mode == MODE_REALTIME && sc->task_count > 0) {
        TaskNode* c = sc->task_queue_head;
        while (c) { sim->request_wait_ticks_sum++; c = c->next; }
    }
}

/**
 * @brief 실시간 모드일 경우, 주기적으로 대시보드를 출력할지 결정하고 시간을 진행시킵니다.
 * @param sim 시뮬레이션 인스턴스
 */
static void maybe_report_realtime_dashboard(Simulation* sim) {
    ScenarioManager* sc = sim->scenario_manager;
    sc->time_step++;
    if (sc->mode == MODE_REALTIME && (sc->time_step % DASHBOARD_INTERVAL_STEPS) == 0) {
        simulation_report_realtime_dashboard(sim);
    }
}

// APPEND_FMT 매크로가 정의되어 있다는 전제하에 교체된 버전
static int GridMap_renderToBuffer(char* buffer, size_t buffer_size,
    const GridMap* map, const AgentManager* am)
{
    static char view[GRID_HEIGHT][GRID_WIDTH];
    static const char* colors[GRID_HEIGHT][GRID_WIDTH];
    char* p = buffer;
    size_t rem = buffer_size;

    // 1) 기본 바닥 채우기
    for (int y = 0; y < GRID_HEIGHT; y++) {
        for (int x = 0; x < GRID_WIDTH; x++) {
            const Node* n = &map->grid[y][x];
            if (n->is_obstacle) { view[y][x] = '+'; colors[y][x] = C_WHT; }
            else { view[y][x] = '.'; colors[y][x] = C_GRY; }
        }
    }

    // 2) 충전소 표시 (충전 중이면 빨강, 아니면 노랑)
    {
        int ncs = map->num_charge_stations;
        for (int i = 0; i < ncs; i++) {
            Node* cs = map->charge_stations[i];
            view[cs->y][cs->x] = 'e';
            if (!g_renderer.simple_colors) {
                int charging = FALSE;
                for (int j = 0; j < MAX_AGENTS; j++) {
                    if (am->agents[j].state == CHARGING && am->agents[j].pos == cs) { charging = TRUE; break; }
                }
                colors[cs->y][cs->x] = charging ? C_B_RED : C_B_YEL;
            }
        }
    }

    // 3) 목표/주차된 차량 표시
    {
        int ng = map->num_goals;
        for (int i = 0; i < ng; i++) {
            Node* g = map->goals[i];
            if (g->is_parked) { view[g->y][g->x] = 'P'; if (!g_renderer.simple_colors) colors[g->y][g->x] = C_RED; }
            else if (g->is_goal) { view[g->y][g->x] = 'G'; if (!g_renderer.simple_colors) colors[g->y][g->x] = C_GRN; }
        }
    }

    // 4) 에이전트 오버레이
    for (int i = 0; i < MAX_AGENTS; i++) {
        if (am->agents[i].pos) {
            Node* n = am->agents[i].pos;
            view[n->y][n->x] = am->agents[i].symbol;
            colors[n->y][n->x] = AGENT_COLORS[i % 10];
        }
    }

    // 5) 헤더와 그리드 출력(버퍼에만 기록)
    APPEND_FMT(p, rem, "%s\n--- D* Lite + WHCA* + WFG(SCC) + partial CBS ---%s\n", C_B_WHT, C_NRM);

    if (g_renderer.simple_colors) {
        for (int y = 0; y < GRID_HEIGHT; y++) {
            for (int x = 0; x < GRID_WIDTH; x++) {
                if (rem <= 1) break;
                *p++ = view[y][x]; rem--;
            }
            if (rem <= 1) break;
            *p++ = '\n'; rem--;
        }
    }
    else {
        for (int y = 0; y < GRID_HEIGHT; y++) {
            for (int x = 0; x < GRID_WIDTH; x++) {
                APPEND_FMT(p, rem, "%s%c%s", colors[y][x], view[y][x], C_NRM);
            }
            APPEND_FMT(p, rem, "\n");
        }
    }
    APPEND_FMT(p, rem, "\n");

    return (int)(p - buffer);
}


/**
 * @brief 시뮬레이션의 현재 상태(통계, 맵, 에이전트 정보, 로그 등)를 종합하여
 *        전역 디스플레이 버퍼(`g_display_buf`)에 텍스트 UI를 구성하고 화면에 출력합니다.
 * @param sim 시뮬레이션 인스턴스
 * @param is_paused 현재 시뮬레이션이 일시정지 상태인지 여부
 */
static void simulation_display_status(const Simulation* sim, int is_paused) {
    const ScenarioManager* sc = sim->scenario_manager;
    const AgentManager* am = sim->agent_manager;
    const GridMap* map = sim->map;
    const Logger* lg = sim->logger;
    const int display_steps = (sim->total_executed_steps > 0) ? sim->total_executed_steps : sc->time_step;
    const double avg_cpu_ms = (display_steps > 0) ? (sim->total_cpu_time_ms / (double)display_steps) : 0.0;

    char* p = g_display_buf;
    size_t rem = sizeof(g_display_buf);


    // 제목/상단 상태
    APPEND_FMT(p, rem, "%s", C_B_WHT);
    if (sc->mode == MODE_CUSTOM) {
        if (sc->current_phase_index < sc->num_phases) {
            const DynamicPhase* ph = &sc->phases[sc->current_phase_index];
            APPEND_FMT(p, rem, "--- Custom Scenario: %d/%d [Speed: %.1fx] ---  (Map #%d)",
                sc->current_phase_index + 1, sc->num_phases, sc->speed_multiplier, sim->map_id);
            if (is_paused) APPEND_FMT(p, rem, " %s[ PAUSED ]%s", C_B_YEL, C_B_WHT);
            APPEND_FMT(p, rem, "\n");

            APPEND_FMT(p, rem, "Time: %d, Current Task: %s (%d/%d)\n",
                sc->time_step, ph->type_name, sc->tasks_completed_in_phase, ph->task_count);
        }
        else {
            APPEND_FMT(p, rem, "--- Custom Scenario: All phases complete ---  (Map #%d)\n", sim->map_id);
        }
    }
    else if (sc->mode == MODE_REALTIME) {
        APPEND_FMT(p, rem, "--- Real-Time Simulation [Speed: %.1fx] ---  (Map #%d)",
            sc->speed_multiplier, sim->map_id);
        if (is_paused) APPEND_FMT(p, rem, " %s[ PAUSED ]%s", C_B_YEL, C_B_WHT);
        APPEND_FMT(p, rem, "\n");

        int park = 0, exitc = 0;
        const TaskNode* t = sc->task_queue_head;
        while (t) {
            if (t->type == TASK_PARK) park++;
            else if (t->type == TASK_EXIT) exitc++;
            t = t->next;
        }
        APPEND_FMT(p, rem, "Time: %d / %d | Pending Tasks: %d (%sPark: %d%s, %sExit: %d%s)\n",
            sc->time_step, REALTIME_MODE_TIMELIMIT, sc->task_count,
            C_B_GRN, park, C_NRM, C_B_YEL, exitc, C_NRM);
    }
    APPEND_FMT(p, rem, "Parked Cars: %d/%d\n%s", am->total_cars_parked, map->num_goals, C_NRM);
    APPEND_FMT(p, rem, "CPU Time (ms) - Last: %.3f | Avg: %.3f | Total: %.2f\n",
        sim->last_step_cpu_time_ms, avg_cpu_ms, sim->total_cpu_time_ms);

    // 알고리즘 표시
    {
        const char* algo = "Default (WHCA*+D*Lite+WFG+CBS)";
        if (sim->path_algo == PATHALGO_ASTAR_SIMPLE) algo = "A* (단순)";
        else if (sim->path_algo == PATHALGO_DSTAR_BASIC) algo = "D* Lite (기본)";
        APPEND_FMT(p, rem, "%sPath Algo:%s %s\n", C_B_WHT, C_NRM, algo);
    }

    APPEND_FMT(p, rem, "%sWHCA horizon:%s %d  | wf_edges(last): %d  | SCC(last): %d  | CBS(last): %s (exp:%d)\n",
        C_B_WHT, C_NRM, g_whca_horizon, g_metrics.wf_edges_last, g_metrics.scc_last,
        g_metrics.cbs_ok_last ? "OK" : "FAIL", g_metrics.cbs_exp_last);

    // 맵 렌더링(서브 함수가 안전하게 rem 범위 내에서만 기록)
    {
        int w = GridMap_renderToBuffer(p, rem, map, am);
        if (w < 0) w = 0;
        if ((size_t)w >= rem) { p += rem - 1; rem = 1; }
        else { p += w; rem -= w; }
    }

    // 에이전트 상태 패널
    {
        static const char* stS[] = {
            "대기","주차 중","기지 복귀(빈 차)","수거 중","출차 중","충전소로 이동","충전 중","기지 복귀(충전 후)"
        };
        static const char* stC[] = { C_GRY,C_YEL,C_CYN,C_YEL,C_GRN,C_B_RED,C_RED,C_CYN };

        for (int i = 0; i < MAX_AGENTS; i++) {
            const Agent* ag = &am->agents[i];
            const char* c = AGENT_COLORS[i % 10];

            char sbuf[100];
            if (ag->state == CHARGING)
                snprintf(sbuf, sizeof(sbuf), "충전 중... (%d)", ag->charge_timer);
            else
                snprintf(sbuf, sizeof(sbuf), "%s", stS[ag->state]);

            APPEND_FMT(p, rem, "%sAgent %c%s: (%2d,%d) ",
                c, ag->symbol, C_NRM,
                ag->pos ? ag->pos->x : -1, ag->pos ? ag->pos->y : -1);

            if (ag->goal)
                APPEND_FMT(p, rem, "-> (%2d,%d) ", ag->goal->x, ag->goal->y);
            else
                APPEND_FMT(p, rem, "-> 없음        ");

            APPEND_FMT(p, rem, "[Mileage: %6.1f/%d] [%s%-*s%s]  [stuck:%d]\n",
                ag->total_distance_traveled, (int)DISTANCE_BEFORE_CHARGE,
                stC[ag->state], STATUS_STRING_WIDTH, sbuf, C_NRM, ag->stuck_steps);
        }
        APPEND_FMT(p, rem, "\n");
    }

    // 로그
    APPEND_FMT(p, rem, "%s--- Simulation Log ---%s\n", C_B_WHT, C_NRM);
    for (int i = 0; i < lg->log_count; i++) {
        int idx = (lg->log_head + i) % LOG_BUFFER_LINES;
        APPEND_FMT(p, rem, "%s%s%s\n", C_GRY, lg->logs[idx], C_NRM);
        if (rem < 512) break; // 과도한 포맷 반복 방지로 성능 보호
    }

    // *** NEW *** 조작 키 안내 추가
    ui_append_controls_help(&p, &rem);

    // 화면 갱신 (프레임 스킵 적용)
    static int s_frame_counter = 0;
    s_frame_counter++;
    if ((s_frame_counter % (g_renderer.render_stride > 0 ? g_renderer.render_stride : 1)) == 0) {
        ui_flush_display_buffer();
    }
}

// =============================================================================
// 4.5) Renderer Facade Implementation (delegates to simulation_display_status)
// =============================================================================
static void renderer_draw_frame_impl(struct Simulation_* sim, int is_paused) {
    simulation_display_status(sim, is_paused);
}
static RendererFacade renderer_create_facade(void) {
    RendererFacade f; f.vtbl.draw_frame = renderer_draw_frame_impl; return f;
}


// Logger
Logger* logger_create() { Logger* l = (Logger*)calloc(1, sizeof(Logger)); if (!l) { perror("Logger"); exit(1); } return l; }
void logger_destroy(Logger* l) { if (l) free(l); }
void logger_log(Logger* l, const char* fmt, ...) {
    va_list a; va_start(a, fmt);
    int idx = (l->log_head + l->log_count) % LOG_BUFFER_LINES;
    vsnprintf(l->logs[idx], LOG_BUFFER_WIDTH, fmt, a);
    va_end(a);
    if (l->log_count < LOG_BUFFER_LINES) l->log_count++;
    else l->log_head = (l->log_head + 1) % LOG_BUFFER_LINES;
}

// OO-style aliases (kept as inline wrappers for readability; behavior unchanged)
#define Logger_log logger_log
#define Logger_create logger_create
#define Logger_destroy logger_destroy

// =============================================================================
// 섹션 5: 그리드 및 맵 관리 (맵 시나리오 1~5 지원)
// =============================================================================
/**
 * @brief 맵의 모든 셀을 장애물이 없는 빈 공간으로 초기화합니다.
 * @param m 초기화할 GridMap 포인터
 */
static void map_all_free(GridMap* m) {
    grid_map_clear(m); // Initialize all cells to free space
}

/**
 * @brief 맵의 가장자리에 벽(장애물)을 추가합니다.
 * @param m 벽을 추가할 GridMap 포인터
 */
static void map_add_border_walls(GridMap* m) {
    for (int x = 0; x < GRID_WIDTH; ++x) {
        m->grid[0][x].is_obstacle = TRUE;
        m->grid[GRID_HEIGHT - 1][x].is_obstacle = TRUE;
    }
    for (int y = 0; y < GRID_HEIGHT; ++y) {
        m->grid[y][0].is_obstacle = TRUE;
        m->grid[y][GRID_WIDTH - 1].is_obstacle = TRUE;
    }
}

/**
 * @brief 지정된 좌표에 주차 공간(goal)을 배치합니다.
 *        해당 위치가 유효하고, 장애물이 아니며, 이미 주차 공간이 아닐 경우에만 배치됩니다.
 * @param m 주차 공간을 배치할 GridMap 포인터
 * @param x 배치할 x 좌표
 * @param y 배치할 y 좌표
 */
static void map_place_goal(GridMap* m, int x, int y) {
    if (!grid_is_valid_coord(x, y)) return;
    Node* n = &m->grid[y][x];
    if (!n->is_obstacle && !n->is_goal) {
        n->is_goal = TRUE;
        if (m->num_goals < MAX_GOALS) m->goals[m->num_goals++] = n;
    }
}

static void map_place_charge(GridMap* m, int x, int y) {
    if (!grid_is_valid_coord(x, y)) return;
    Node* n = &m->grid[y][x];
    if (!n->is_obstacle) {
        if (m->num_charge_stations < MAX_CHARGE_STATIONS)
            m->charge_stations[m->num_charge_stations++] = n;
    }
}

static void map_place_agent_at(AgentManager* am, GridMap* m, int idx, int x, int y) {
    if (idx < 0 || idx >= MAX_AGENTS) return;
    Node* n = &m->grid[y][x];
    am->agents[idx].pos = n;
    am->agents[idx].home_base = n;
    am->agents[idx].symbol = 'A' + idx; // A..J
    am->agents[idx].heading = DIR_NONE;
    am->agents[idx].rotation_wait = 0;
}

static void map_reserve_area_as_start(GridMap* m, int x0, int y0, int w, int h) {
    for (int y = y0; y < y0 + h && y < GRID_HEIGHT; ++y)
        for (int x = x0; x < x0 + w && x < GRID_WIDTH; ++x) {
            Node* n = &m->grid[y][x];
            n->is_obstacle = FALSE;
            n->is_goal = FALSE;
            n->is_temp = FALSE;
        }
}

static void agent_manager_reset_for_new_map(AgentManager* am) {
    if (!am) return;
    for (int i = 0; i < MAX_AGENTS; i++) {
        if (am->agents[i].pf) { pathfinder_destroy(am->agents[i].pf); am->agents[i].pf = NULL; }
        am->agents[i].id = i;
        am->agents[i].symbol = 'A' + i;
        am->agents[i].pos = NULL;
        am->agents[i].home_base = NULL;
        am->agents[i].goal = NULL;
        am->agents[i].state = IDLE;
        am->agents[i].total_distance_traveled = 0.0;
        am->agents[i].charge_timer = 0;
        am->agents[i].action_timer = 0;
        am->agents[i].heading = DIR_NONE;
        am->agents[i].rotation_wait = 0;
        am->agents[i].stuck_steps = 0;
        am->agents[i].metrics_task_active = 0;
        am->agents[i].metrics_task_start_step = 0;
        am->agents[i].metrics_distance_at_start = 0.0;
        am->agents[i].metrics_turns_current = 0;
    }
    am->total_cars_parked = 0;
}

static void grid_map_clear(GridMap* map) {
    memset(map, 0, sizeof(*map));
    for (int y = 0; y < GRID_HEIGHT; ++y)
        for (int x = 0; x < GRID_WIDTH; ++x) {
            map->grid[y][x].x = x;
            map->grid[y][x].y = y;
            map->grid[y][x].is_obstacle = FALSE;
            map->grid[y][x].is_goal = FALSE;
            map->grid[y][x].is_temp = FALSE;
            map->grid[y][x].is_parked = FALSE;
            map->grid[y][x].reserved_by_agent = -1;
        }
    map->num_goals = 0;
    map->num_charge_stations = 0;
}

static void grid_map_fill_from_string(GridMap* map, AgentManager* am, const char* m) {
    grid_map_clear(map);

    int x = 0, y = 0;
    int last_was_cr = 0; /* CRLF를 한 번만 개행 처리하기 위한 플래그 */

    for (const char* p = m; *p && y < GRID_HEIGHT; ++p) {
        char ch = *p;

        /* 개행 처리: CRLF/LF 모두 지원 */
        if (ch == '\r') {
            x = 0; y++; last_was_cr = 1;
            continue;
        }
        if (ch == '\n') {
            if (!last_was_cr) { x = 0; y++; }
            last_was_cr = 0;
            continue;
        }
        last_was_cr = 0;

        /* 현재 줄에서 그리드 폭 초과 문자는 버리고 개행 나올 때까지 스킵 */
        if (x >= GRID_WIDTH) continue;
        if (y >= GRID_HEIGHT) break;

        Node* n = &map->grid[y][x];

        /* 기본: 빈칸(장애물 아님)로 시작 - grid_map_clear에서 이미 설정됨 */
        n->is_obstacle = FALSE;
        n->is_goal = FALSE;
        n->is_temp = FALSE;
        n->is_parked = FALSE;
        n->reserved_by_agent = -1;

        switch (ch) {
        case '1':  /* 벽/장애물 */
            n->is_obstacle = TRUE;
            break;

        case 'A':  /* 에이전트 A */
            am->agents[0].pos = n;
            am->agents[0].home_base = n;
            break;

        case 'B':  /* 에이전트 B */
            am->agents[1].pos = n;
            am->agents[1].home_base = n;
            break;

        case 'C':  /* 에이전트 C */
            am->agents[2].pos = n;
            am->agents[2].home_base = n;
            break;

        case 'D':  /* 에이전트 D */
            am->agents[3].pos = n;
            am->agents[3].home_base = n;
            break;

        case 'G':  /* 주차 목표칸 */
            n->is_goal = TRUE;
            if (map->num_goals < MAX_GOALS) map->goals[map->num_goals++] = n;
            break;

        case 'e':  /* 충전소 */
            if (map->num_charge_stations < MAX_CHARGE_STATIONS)
                map->charge_stations[map->num_charge_stations++] = n;
            break;

        case '0':  /* 빈칸 */
        default:
            /* 아무 것도 안 함(빈칸) */
            break;
        }

        x++;
    }

    /* 남은 영역은 grid_map_clear()의 기본(빈칸) 유지 → 좌상단 정렬 상태로 끝 */
}


void grid_map_load_scenario(GridMap* map, AgentManager* am, int scenario_id) {
    agent_manager_reset_for_new_map(am);
    grid_map_clear(map);

    switch (scenario_id) {
    case 1: {
        static const char* MAP1 =
            "1111111111111111111111111111111111111\n"
            "001GGG1GG1GGG1GGG1GGG1GGG1GGG1G11G111\n"
            "A000000000000000000000000000000000001\n"
            "B000000000000000000000000000000000001\n"
            "C001GG1GG1GGG10001GGG1GGG1GGG1100e111\n"
            "111111111111110001GGG1GGG1GGG11001111\n"
            "100000000000000000000000000000000e111\n"
            "100000000000000000000000000000000e111\n"
            "11111111111111GGG1GGG1GGG1GGG1GG11111\n"
            "1111111111111111111111111111111111111\n"
            "1111111111111111111111111111111111111\n"
            "1111111111111111111111111111111111111\n";
        grid_map_fill_from_string(map, am, MAP1);
        break;
    }
    case 2: map_build_hypermart(map, am);              break; // 대형마트 주차장
    case 3: map_build_10agents_200slots(map, am);      break; // 8대 + 900칸 + 16x6
    case 4: map_build_biggrid_onegoal(map, am);        break; // 격자도로 + 주차블록 4개
    case 5: map_build_cross_4agents(map, am);          break; // 십자가맵
    default:
        map_build_hypermart(map, am); // fallback
        break;
    }
}
// #2: 알고리즘 테스트 전용 하이퍼마트 테스트베드 (우측 도달성 수정 포함)
static void map_build_hypermart(GridMap* m, AgentManager* am) {
    int x, y;

    // 0) 초기화 + 외곽벽
    map_all_free(m);
    map_add_border_walls(m);

    // 1) 내부를 모두 막아두고(장애물) → 도로만 "깎는" 방식
    for (y = 1; y < GRID_HEIGHT - 1; ++y)
        for (x = 1; x < GRID_WIDTH - 1; ++x) {
            m->grid[y][x].is_obstacle = TRUE;
            m->grid[y][x].is_goal = FALSE;
        }

    // 2) 스타트 패드 + AGV 4대
    map_reserve_area_as_start(m, 2, 2, 8, 5);
    map_place_agent_at(am, m, 0, 2, 2);
    map_place_agent_at(am, m, 1, 3, 2);
    map_place_agent_at(am, m, 2, 4, 2);
    map_place_agent_at(am, m, 3, 5, 2);

    // 3) 상단 피더(가로 1차선)
    for (x = 1; x < GRID_WIDTH - 1; ++x) m->grid[6][x].is_obstacle = FALSE;

    // 4) 세로 메인 레인(전부 1차선)
    const int vCols[] = { 12, 22, 32, 42, 52, 62, 72 };
    const int nV = (int)(sizeof(vCols) / sizeof(vCols[0]));
    for (int i = 0; i < nV; ++i) {
        int cx = vCols[i];
        for (y = 1; y < GRID_HEIGHT - 1; ++y) m->grid[y][cx].is_obstacle = FALSE;
    }

    // 5) 전폭 개방 교차로 2곳 + 중앙 협곡
    for (x = 1; x < GRID_WIDTH - 1; ++x) {
        m->grid[10][x].is_obstacle = FALSE;
        m->grid[30][x].is_obstacle = FALSE;
    }
    for (y = 19; y <= 21; ++y)
        for (x = 1; x < GRID_WIDTH - 1; ++x)
            m->grid[y][x].is_obstacle = TRUE;

    // 협곡에서도 세로 레인은 유지
    for (int i = 0; i < nV; ++i) {
        int cx = vCols[i];
        for (y = 19; y <= 21; ++y) m->grid[y][cx].is_obstacle = FALSE;
    }
    // 협곡 추가 개구
    m->grid[20][34].is_obstacle = FALSE;
    m->grid[20][50].is_obstacle = FALSE;

    // 6) 좌측 서비스 레인
    for (y = 1; y < GRID_HEIGHT - 1; ++y) m->grid[y][4].is_obstacle = FALSE;
    for (x = 4; x <= 10; ++x) m->grid[6][x].is_obstacle = FALSE;

    // 7) 풀오버 포켓
    const int pocketY[] = { 14, 16, 26, 28, 34 };
    const int nP = (int)(sizeof(pocketY) / sizeof(pocketY[0]));
    for (int i = 0; i < nV; ++i) {
        int cx = vCols[i];
        for (int k = 0; k < nP; ++k) {
            int py = pocketY[k];
            if (py >= 19 && py <= 21) continue;
            if (py == 10 || py == 30) continue;
            if (grid_is_valid_coord(cx - 1, py)) m->grid[py][cx - 1].is_obstacle = FALSE;
            if (grid_is_valid_coord(cx + 1, py)) m->grid[py][cx + 1].is_obstacle = FALSE;
        }
    }

    // 8) 충전소 4곳
    map_place_charge(m, 12, 8);
    map_place_charge(m, 42, 8);
    map_place_charge(m, 42, 32);
    map_place_charge(m, 72, 8);

    // 9) 주차 금지 행 마크
    int markRow[GRID_HEIGHT] = { 0 };
    markRow[6] = 1;
    markRow[10] = 1;
    markRow[19] = 1; markRow[20] = 1; markRow[21] = 1;
    markRow[30] = 1;

    // 10) 각 세로 레인 양옆 인접열에 목표칸
    const int y_min = 8, y_max = GRID_HEIGHT - 4;
    for (int i = 0; i < nV; ++i) {
        int roadX = vCols[i];
        int leftCol = roadX - 1;
        int rightCol = roadX + 1;
        for (y = y_min; y <= y_max; ++y) {
            if (markRow[y]) continue;
            if (grid_is_valid_coord(leftCol, y)) { m->grid[y][leftCol].is_obstacle = FALSE; map_place_goal(m, leftCol, y); }
            if (grid_is_valid_coord(rightCol, y)) { m->grid[y][rightCol].is_obstacle = FALSE; map_place_goal(m, rightCol, y); }
        }
    }

    // 11) (★수정 핵심) 우측 외곽 라인: 도로 + 목표 한 쌍으로 배치
    const int side_right_col = GRID_WIDTH - 4; // 목표 열
    const int side_right_road = GRID_WIDTH - 5; // 이 열을 '도로'로 새로 팜
    // 11-1) 수직도로 개설 (협곡 구간 포함)
    for (y = 1; y < GRID_HEIGHT - 1; ++y) m->grid[y][side_right_road].is_obstacle = FALSE;
    for (y = 19; y <= 21; ++y)            m->grid[y][side_right_road].is_obstacle = FALSE; // 협곡 관통 보장
    // 11-2) 도로 오른쪽에 목표칸(항상 인접통로 확보)
    for (y = y_min; y <= y_max; ++y) {
        if (markRow[y]) continue;
        if (grid_is_valid_coord(side_right_col, y)) {
            m->grid[y][side_right_col].is_obstacle = FALSE;
            map_place_goal(m, side_right_col, y);
        }
    }

    // 12) 스타트/서비스 근처 목표 제거
    for (y = 2; y <= 8; ++y)
        for (x = 2; x <= 8; ++x)
            m->grid[y][x].is_goal = FALSE;
    for (y = 1; y < GRID_HEIGHT - 1; ++y) m->grid[y][4].is_goal = FALSE;

    // 13) (안전장치) 목표 위생: 4방이 모두 벽/외곽이면 목표 해제
    m->num_goals = 0;
    for (y = 1; y < GRID_HEIGHT - 1; ++y) {
        for (x = 1; x < GRID_WIDTH - 1; ++x) {
            Node* n = &m->grid[y][x];
            if (!n->is_goal) continue;
            int ok = 0;
            const int dx[4] = { 1,-1,0,0 }, dy[4] = { 0,0,1,-1 };
            for (int k = 0; k < 4; k++) {
                int nx = x + dx[k], ny = y + dy[k];
                if (!grid_is_valid_coord(nx, ny)) continue;
                if (!m->grid[ny][nx].is_obstacle) { ok = 1; break; }
            }
            if (!ok) n->is_goal = FALSE; // 고립 목표 제거
            if (n->is_goal && m->num_goals < MAX_GOALS) m->goals[m->num_goals++] = n;
        }
    }
}

// #3: 8 agents + 900 parking slots
// - 좌측 2차선 세로도로(x=2,3) + y=6,7 가로 2차선 피더 유지
// - 스타트 영역을 10x4 → 16x6으로 '살짝' 확장
// - 확장된 스타트 영역 내부에 충전소 4개(2x2) 배치
// - 모든 주차칸은 도로와 한 면을 접하도록 배치하며 좌측 2차선 주변에는 G를 만들지 않음
static void map_build_10agents_200slots(GridMap* m, AgentManager* am) {
    int x, y;

    /* 0) 초기화 + 외곽벽 */
    map_all_free(m);
    map_add_border_walls(m);

    /* 1) 내부를 전부 장애물로 채움(도로만 깎는다) */
    for (y = 1; y < GRID_HEIGHT - 1; ++y)
        for (x = 1; x < GRID_WIDTH - 1; ++x) {
            m->grid[y][x].is_obstacle = TRUE;
            m->grid[y][x].is_goal = FALSE;
        }

    /* 2) 스타트 영역 확장: (2,2)에서 16×6 */
    const int sx0 = 2, sy0 = 2;
    const int sW = 16, sH = 6;                 // ★ 확장
    map_reserve_area_as_start(m, sx0, sy0, sW, sH);

    /* A..H 배치(8대) */
    for (int i = 0; i < 8; ++i) {
        int row = i / 5, col = i % 5;
        map_place_agent_at(am, m, i, sx0 + col * 2, sy0 + row * 2);
    }

    /* ===== 도로 파라미터 ===== */
    const int lane_w = 1;          // 나머지 도로 폭(1차선)
    const int y_min = 8;          // 주차 시작 y (스타트/피더 아래)
    const int y_max = GRID_HEIGHT - 5;

    // 세로 메인도로(1차선): x=16..(W-6), step 4
    const int ax_start = 16;
    const int ax_end = GRID_WIDTH - 6;
    const int ax_step = 4;

    // 가로 연결도로(1차선): y=10..(H-6), step 6
    const int cross_start = 10;
    const int cross_end = GRID_HEIGHT - 6;
    const int cross_step = 6;

    /* 3) 좌측 2차선 세로 주도로(x=2,3) */
    for (y = 1; y < GRID_HEIGHT - 1; ++y) {
        if (grid_is_valid_coord(2, y)) m->grid[y][2].is_obstacle = FALSE;
        if (grid_is_valid_coord(3, y)) m->grid[y][3].is_obstacle = FALSE;
    }

    /* 4) 스타트 아래 가로 2차선 피더(y=6,7) */
    for (x = 1; x < GRID_WIDTH - 1; ++x) {
        if (grid_is_valid_coord(x, 6)) m->grid[6][x].is_obstacle = FALSE;
        if (grid_is_valid_coord(x, 7)) m->grid[7][x].is_obstacle = FALSE;
    }

    /* 5) 세로 메인도로(1차선) */
    for (x = ax_start; x <= ax_end; x += ax_step)
        for (y = 1; y < GRID_HEIGHT - 1; ++y)
            m->grid[y][x].is_obstacle = FALSE;

    /* 6) 가로 연결도로(1차선) */
    for (y = cross_start; y <= cross_end; y += cross_step)
        for (x = 1; x < GRID_WIDTH - 1; ++x)
            m->grid[y][x].is_obstacle = FALSE;

    /* 7) ★충전소 4개: 시작 박스 좌측벽 라인으로 배치(2×2 형태) */
    // 시작 영역의 좌측 경계(sx0) 근처에 밀착 배치하여 접근성 확보
    {
        int cxL = sx0;          // 시작 박스 좌측벽 열
        int cyT = sy0 + 1;      // 시작 박스 상단에서 한 칸 아래
        map_place_charge(m, cxL, cyT);
        map_place_charge(m, cxL + 1, cyT);
        map_place_charge(m, cxL, cyT + 2);
        map_place_charge(m, cxL + 1, cyT + 2);
    }

    /* 8) 주차 금지 행/열 마크 (교차로/피더 행 + 모든 세로차선 열) */
    int markRow[GRID_HEIGHT] = { 0 };
    markRow[6] = 1; markRow[7] = 1;                  // 2차선 피더
    for (y = cross_start; y <= cross_end; y += cross_step)
        if (y >= 0 && y < GRID_HEIGHT) markRow[y] = 1;

    int markCol[GRID_WIDTH] = { 0 };
    markCol[2] = 1; markCol[3] = 1;                  // 좌측 2차선 주도로
    for (x = ax_start; x <= ax_end; x += ax_step)
        if (x >= 0 && x < GRID_WIDTH) markCol[x] = 1;

    /* 9) 1차 패스: 세로 메인도로 좌/우 인접열에 촘촘 배치 */
    const int target = 900;
    int placed = 0;
    for (x = ax_start; x <= ax_end && placed < target; x += ax_step) {
        int leftCol = x - 1;
        int rightCol = x + lane_w; // x+1
        for (y = y_min; y <= y_max && placed < target; ++y) {
            if (markRow[y]) continue;               // 교차로/피더 행은 비움

            if (grid_is_valid_coord(leftCol, y) && placed < target) {
                m->grid[y][leftCol].is_obstacle = FALSE;
                map_place_goal(m, leftCol, y);
                placed++;
            }
            if (grid_is_valid_coord(rightCol, y) && placed < target) {
                m->grid[y][rightCol].is_obstacle = FALSE;
                map_place_goal(m, rightCol, y);
                placed++;
            }
        }
    }

    /* 10) 2차 패스(부족분): 가로도로 위/아래 한 칸(수직도로 열은 건너뜀) */
    if (placed < target) {
        for (y = cross_start; y <= cross_end && placed < target; y += cross_step) {
            int row = y;
            for (x = 2; x < GRID_WIDTH - 2 && placed < target; ++x) {
                if (markCol[x]) continue;                   // 수직 통로 유지
                if (m->grid[row][x].is_obstacle != FALSE) continue; // 실제 가로도로만

                if (grid_is_valid_coord(x, row - 1) &&
                    !m->grid[row - 1][x].is_goal && placed < target) {
                    m->grid[row - 1][x].is_obstacle = FALSE;
                    map_place_goal(m, x, row - 1);
                    placed++;
                }
                if (grid_is_valid_coord(x, row + 1) &&
                    !m->grid[row + 1][x].is_goal && placed < target) {
                    m->grid[row + 1][x].is_obstacle = FALSE;
                    map_place_goal(m, x, row + 1);
                    placed++;
                }
            }
        }
    }

    /* 11) 안전: 좌측 주도로(x=2,3)는 절대 G 금지 */
    for (y = 1; y < GRID_HEIGHT - 1; ++y) {
        m->grid[y][2].is_goal = FALSE;
        m->grid[y][3].is_goal = FALSE;
    }
}

// ──────────────────────────────────────────────────────────────
// 1-차선 주차블록 + 1-칸 링도로 + 격자도로로의 연결(가까운 격자선에 스냅)
// cx,cy : 블록 중심 / Wg,Hg : 블록 가로x세로 크기(예: 6x2)
// vstep,hstep,vx0,hy0 : 격자도로 간격/시작좌표 (세로/가로)
// CX,CY : 맵 중심(시작영역 기준, 연결 방향 선택에 사용)
// ──────────────────────────────────────────────────────────────
static void carve_block_1lane(GridMap* m,
    int cx, int cy, int Wg, int Hg,
    int vstep, int hstep, int vx0, int hy0,
    int CX, int CY)
{
    int x, y;

    // 1) 목표 블록(통행 가능 + G 표시)
    int gx0 = cx - (Wg / 2 - 1);
    int gx1 = gx0 + Wg - 1;
    int gy0 = cy - (Hg / 2);
    int gy1 = gy0 + Hg - 1;

    for (y = gy0; y <= gy1; ++y)
        for (x = gx0; x <= gx1; ++x) {
            if (!grid_is_valid_coord(x, y)) continue;
            m->grid[y][x].is_obstacle = FALSE;
            map_place_goal(m, x, y);
        }

    // 2) 블록을 감싸는 1칸 폭 링도로
    int rxL = gx0 - 1, rxR = gx1 + 1;
    int ryT = gy0 - 1, ryB = gy1 + 1;

    for (x = gx0 - 1; x <= gx1 + 1; ++x) {
        if (grid_is_valid_coord(x, ryT)) m->grid[ryT][x].is_obstacle = FALSE;
        if (grid_is_valid_coord(x, ryB)) m->grid[ryB][x].is_obstacle = FALSE;
    }
    for (y = gy0 - 1; y <= gy1 + 1; ++y) {
        if (grid_is_valid_coord(rxL, y)) m->grid[y][rxL].is_obstacle = FALSE;
        if (grid_is_valid_coord(rxR, y)) m->grid[y][rxR].is_obstacle = FALSE;
    }

    // 3) 격자도로에 1칸 폭으로 연결(가까운 세로/가로 격자선에 스냅)
    //    세로 격자선 x = vx0 + k*vstep, 가로 격자선 y = hy0 + k*hstep
    int kx = (cx - vx0 + vstep / 2) / vstep;
    int vx = vx0 + kx * vstep;
    if (vx < 1) vx = 1;
    if (vx > GRID_WIDTH - 2) vx = GRID_WIDTH - 2;

    int ky = (cy - hy0 + hstep / 2) / hstep;
    int hy = hy0 + ky * hstep;
    if (hy < 1) hy = 1;
    if (hy > GRID_HEIGHT - 2) hy = GRID_HEIGHT - 2;

    // 수평 연결: 링 상/하 중 중심(CY)에 더 가까운 쪽 선택
    {
        int linkY = (abs(ryT - CY) <= abs(ryB - CY)) ? ryT : ryB;
        if (vx <= rxL) { for (x = vx; x <= rxL; ++x) m->grid[linkY][x].is_obstacle = FALSE; }
        else if (vx >= rxR) { for (x = rxR; x <= vx; ++x) m->grid[linkY][x].is_obstacle = FALSE; }
        else { m->grid[linkY][vx].is_obstacle = FALSE; }
    }
    // 수직 연결: 링 좌/우 중 중심(CX)에 더 가까운 쪽 선택
    {
        int linkX = (abs(rxL - CX) <= abs(rxR - CX)) ? rxL : rxR;
        if (hy <= ryT) { for (y = hy; y <= ryT; ++y) m->grid[y][linkX].is_obstacle = FALSE; }
        else if (hy >= ryB) { for (y = ryB; y <= hy; ++y) m->grid[y][linkX].is_obstacle = FALSE; }
        else { m->grid[hy][linkX].is_obstacle = FALSE; }
    }
}

// #4: 중앙 시작(10x4) + 좌상/우상/좌하/우하 4블록
//     1칸 격자도로(vstep=5,hstep=5) + y=6 피더 + 모든 도로 1차선
static void map_build_biggrid_onegoal(GridMap* m, AgentManager* am) {
    map_all_free(m);
    map_add_border_walls(m);

    int x, y;

    // 내부 전부 막기
    for (y = 1; y < GRID_HEIGHT - 1; ++y)
        for (x = 1; x < GRID_WIDTH - 1; ++x) {
            m->grid[y][x].is_obstacle = TRUE;
            m->grid[y][x].is_goal = FALSE;
        }

    // ── 시작영역: 맵 정중앙 10x4 (A..J) ──
    const int CX = GRID_WIDTH / 2;     // 82x42 기준: 41
    const int CY = GRID_HEIGHT / 2;    // 21
    const int sW = 10, sH = 4;
    const int sx0 = CX - sW / 2;
    const int sy0 = CY - sH / 2;
    map_reserve_area_as_start(m, sx0, sy0, sW, sH);
    for (int i = 0; i < 10; ++i) {
        int row = i / 5, col = i % 5;
        map_place_agent_at(am, m, i, sx0 + col * 2, sy0 + row * 2);
    }

    // ── 1칸 격자도로 ──
    const int vstep = 5, hstep = 5;
    const int vx0 = 6;   // 세로 격자 시작 x
    const int hy0 = 9;   // 가로 격자 시작 y

    // 세로 격자선
    for (x = vx0; x < GRID_WIDTH - 1; x += vstep)
        for (y = 1; y < GRID_HEIGHT - 1; ++y)
            m->grid[y][x].is_obstacle = FALSE;

    // 가로 격자선
    for (y = hy0; y < GRID_HEIGHT - 1; y += hstep)
        for (x = 1; x < GRID_WIDTH - 1; ++x)
            m->grid[y][x].is_obstacle = FALSE;

    // 스타트 → 격자 피더(y=6, 1칸)
    for (x = 1; x < GRID_WIDTH - 1; ++x)
        m->grid[6][x].is_obstacle = FALSE;

    // ── 4개의 주차블록(기존 위치 유지, 중앙에서 충분히 떨어지도록) ──
    const int Wg = 6, Hg = 2;
    const int bxL = 8;
    const int bxR = GRID_WIDTH - 8;
    const int byT = 8;
    const int byB = GRID_HEIGHT - 8;

    // 좌상단
    carve_block_1lane(m, bxL, byT, Wg, Hg, vstep, hstep, vx0, hy0, CX, CY);
    // 우상단
    carve_block_1lane(m, bxR, byT, Wg, Hg, vstep, hstep, vx0, hy0, CX, CY);
    // 좌하단
    carve_block_1lane(m, bxL, byB, Wg, Hg, vstep, hstep, vx0, hy0, CX, CY);
    // 우하단
    carve_block_1lane(m, bxR, byB, Wg, Hg, vstep, hstep, vx0, hy0, CX, CY);

    // 충전소 4곳(중앙 주변)
    if (grid_is_valid_coord(CX, CY - 6)) map_place_charge(m, CX, CY - 6);
    if (grid_is_valid_coord(CX, CY + 6)) map_place_charge(m, CX, CY + 6);
    if (grid_is_valid_coord(CX - 6, CY)) map_place_charge(m, CX - 6, CY);
    if (grid_is_valid_coord(CX + 6, CY)) map_place_charge(m, CX + 6, CY);

    // goals[] 재구축
    m->num_goals = 0;
    for (y = 1; y < GRID_HEIGHT - 1; ++y)
        for (x = 1; x < GRID_WIDTH - 1; ++x)
            if (m->grid[y][x].is_goal && m->num_goals < MAX_GOALS)
                m->goals[m->num_goals++] = &m->grid[y][x];
}

// #5: 십자가 맵 (Cross) - 중앙 충전소, 각 팔 끝에 에이전트, 각 에이전트에서 4칸 진행 지점에 주차칸
static void map_build_cross_4agents(GridMap* m, AgentManager* am) {
    int x, y;

    // 0) 초기화 + 외곽벽
    map_all_free(m);
    map_add_border_walls(m);

    // 1) 내부를 장애물로 채우고 → 십자가(세로/가로 1차선)만 개방
    for (y = 1; y < GRID_HEIGHT - 1; ++y)
        for (x = 1; x < GRID_WIDTH - 1; ++x) {
            m->grid[y][x].is_obstacle = TRUE;
            m->grid[y][x].is_goal = FALSE;
        }

    const int CX = GRID_WIDTH / 2;
    const int CY = GRID_HEIGHT / 2;

    for (y = 1; y < GRID_HEIGHT - 1; ++y) m->grid[y][CX].is_obstacle = FALSE; // 수직 팔
    for (x = 1; x < GRID_WIDTH - 1; ++x) m->grid[CY][x].is_obstacle = FALSE; // 수평 팔

    // 2) 에이전트 배치: 좌/우/상/하 팔 끝(외곽벽 바로 안쪽)
    map_place_agent_at(am, m, 0, 1, CY);                    // 서쪽 끝
    map_place_agent_at(am, m, 1, GRID_WIDTH - 2, CY);       // 동쪽 끝
    map_place_agent_at(am, m, 2, CX, 1);                    // 북쪽 끝
    map_place_agent_at(am, m, 3, CX, GRID_HEIGHT - 2);      // 남쪽 끝

    // 3) 각 에이전트 위치에서 4칸 전진 지점에 주차 목표칸 배치
    map_place_goal(m, 1 + 4, CY);                           // 서쪽 → 동쪽으로 4칸
    map_place_goal(m, GRID_WIDTH - 2 - 4, CY);              // 동쪽 → 서쪽으로 4칸
    map_place_goal(m, CX, 1 + 4);                           // 북쪽 → 남쪽으로 4칸
    map_place_goal(m, CX, GRID_HEIGHT - 2 - 4);             // 남쪽 → 북쪽으로 4칸

    // 4) 중앙 충전소 1개
    map_place_charge(m, CX, CY);
}
GridMap* grid_map_create(AgentManager* am) {
    GridMap* m = (GridMap*)calloc(1, sizeof(GridMap)); if (!m) { perror("GridMap"); exit(1); }
    grid_map_load_scenario(m, am, 1); // 기본 맵 = 1
    return m;
}
void grid_map_destroy(GridMap* m) { if (m) free(m); }

int grid_is_valid_coord(int x, int y) { return (x >= 0 && x < GRID_WIDTH&& y >= 0 && y < GRID_HEIGHT); }

int grid_is_node_blocked(const GridMap* map, const AgentManager* am, const Node* n, const struct Agent_* agent) {
    if (n->is_obstacle || n->is_parked || n->is_temp) return TRUE;

    // 기지 복귀 차량(RETURNING_HOME_EMPTY)은 빈 주차 공간을 이용할 수 없음
    if (agent && agent->state == RETURNING_HOME_EMPTY && n->is_goal && !n->is_parked) {
        return TRUE;
    }

    for (int i = 0; i < MAX_AGENTS; i++) {
        if (am->agents[i].pos == n && am->agents[i].state == CHARGING) return TRUE;
    }
    return FALSE;
}

// =============================================================================
// 섹션 6: 시나리오 및 작업 관리
// =============================================================================
/**
 * @brief 실시간 모드 작업 대기열을 모두 해제하고 카운터를 초기화합니다.
 * @param s 시나리오 매니저 포인터
 */
static void scenario_manager_clear_task_queue(ScenarioManager* s) {
    TaskNode* c = s->task_queue_head; while (c) { TaskNode* nx = c->next; free(c); c = nx; }
    s->task_queue_head = s->task_queue_tail = NULL; s->task_count = 0;
}
/**
 * @brief 시나리오 매니저를 생성합니다.
 *        기본 속도, 확률, 시간 관련 필드를 초기화합니다.
 * @return 생성된 ScenarioManager 포인터 (실패 시 종료)
 */
ScenarioManager* scenario_manager_create() {
    ScenarioManager* s = (ScenarioManager*)calloc(1, sizeof(ScenarioManager));
    if (!s) { perror("Scenario"); exit(1); }
    s->simulation_speed = 100; s->speed_multiplier = 1.0f;
    s->park_chance = 40; s->exit_chance = 30;
    return s;
}
/**
 * @brief 시나리오 매니저를 파괴하고 내부 대기열을 정리합니다.
 * @param s 파괴할 ScenarioManager 포인터
 */
void scenario_manager_destroy(ScenarioManager* s) { if (s) { scenario_manager_clear_task_queue(s); free(s); } }

// --- AgentOps VTable: 에이전트 작업 시작/목표 설정 추상화 ---
typedef struct AgentOps_ {
    void (*beginTaskPark)(Agent* ag, ScenarioManager* sc, Logger* lg);
    void (*beginTaskExit)(Agent* ag, ScenarioManager* sc, Logger* lg);
    void (*setGoalIfNeeded)(Agent* ag, GridMap* map, AgentManager* am, Logger* lg);
} AgentOps;

/**
 * @brief 에이전트에 주차(PARK) 작업을 시작시킵니다.
 *        작업 메트릭을 초기화하고 로그를 기록합니다.
 * @param ag 대상 에이전트
 * @param sc 시나리오 매니저
 * @param lg 로거
 */
static void AgentOps_beginTaskPark_impl(Agent* ag, ScenarioManager* sc, Logger* lg) { agent_begin_task_park(ag, sc, lg); }
/**
 * @brief 에이전트에 출차(EXIT) 작업을 시작시킵니다.
 *        작업 메트릭을 초기화하고 로그를 기록합니다.
 * @param ag 대상 에이전트
 * @param sc 시나리오 매니저
 * @param lg 로거
 */
static void AgentOps_beginTaskExit_impl(Agent* ag, ScenarioManager* sc, Logger* lg) { agent_begin_task_exit(ag, sc, lg); }
// forward declaration to avoid implicit declaration when called here
static void agent_set_goal(Agent* ag, GridMap* map, AgentManager* am, Logger* lg);
/**
 * @brief 목표가 없고 이동 중인 에이전트에게 상태에 맞는 목표를 설정합니다.
 *        IDLE/CHARGING 상태는 제외합니다.
 * @param ag 대상 에이전트
 * @param map 그리드 맵
 * @param am 에이전트 매니저
 * @param lg 로거
 */
static void AgentOps_setGoalIfNeeded_impl(Agent* ag, GridMap* map, AgentManager* am, Logger* lg) {
    if (ag->goal == NULL && ag->state != IDLE && ag->state != CHARGING) agent_set_goal(ag, map, am, lg);
}
static AgentOps g_agent_ops = { AgentOps_beginTaskPark_impl, AgentOps_beginTaskExit_impl, AgentOps_setGoalIfNeeded_impl };
/**
 * @brief 실시간 모드 작업 대기열의 테일에 작업을 추가합니다.
 *        최대 작업 수에 도달하면 무시됩니다.
 * @param s 시나리오 매니저
 * @param t 작업 타입(TASK_PARK/TASK_EXIT)
 */
static void add_task_to_queue(ScenarioManager* s, TaskType t) {
    if (s->task_count >= MAX_TASKS) return;
    TaskNode* n = (TaskNode*)malloc(sizeof(TaskNode)); if (!n) { perror("task"); return; }
    n->type = t; n->created_at_step = s->time_step; n->next = NULL;
    if (!s->task_queue_head) { s->task_queue_head = s->task_queue_tail = n; }
    else { s->task_queue_tail->next = n; s->task_queue_tail = n; }
    s->task_count++;
}

// =============================================================================
// 섹션 7: 우선순위 큐 (Pathfinder용 OPEN 리스트)
// =============================================================================
typedef struct { double k1; double k2; } _cmpKey; // same as Key

/**
 * @brief D* Lite용 Key 비교 함수입니다.
 * @param a 좌측 Key
 * @param b 우측 Key
 * @return a<b:-1, a>b:1, 같으면 0
 */
static int compare_keys(Key a, Key b) {
    if (a.k1 < b.k1 - 1e-9) return -1;
    if (a.k1 > b.k1 + 1e-9) return  1;
    if (a.k2 < b.k2 - 1e-9) return -1;
    if (a.k2 > b.k2 + 1e-9) return  1;
    return 0;
}
/**
 * @brief Pathfinder 내부 셀(SearchCell)에 대한 포인터를 반환합니다.
 * @param pf Pathfinder
 * @param n 대상 노드
 * @return SearchCell 포인터
 */
static inline SearchCell* cell_of(Pathfinder* pf, const Node* n) { return &pf->cells[n->y][n->x]; }
/**
 * @brief 노드의 현재 Key 값을 반환합니다.
 * @param pf Pathfinder
 * @param n 대상 노드
 * @return Key 값
 */
static inline Key key_of(Pathfinder* pf, const Node* n) { return cell_of(pf, n)->key; }

/**
 * @brief 노드 우선순위 큐(힙)를 초기화합니다.
 * @param pq 대상 큐
 * @param cap 최대 용량
 */
static void pq_init(NodePQ* pq, int cap) {
    pq->nodes = (Node**)malloc(sizeof(Node*) * cap); pq->size = 0; pq->capacity = cap;
}
/**
 * @brief 노드 우선순위 큐 리소스를 해제합니다.
 * @param pq 대상 큐
 */
static void pq_free(NodePQ* pq) { if (pq && pq->nodes) { free(pq->nodes); pq->nodes = NULL; } }

/**
 * @brief 힙 내부 두 노드를 교환하고 인덱스 정보를 갱신합니다.
 * @param pf Pathfinder (인덱스 갱신용)
 * @param a 노드 포인터 참조 1
 * @param b 노드 포인터 참조 2
 */
static void pq_swap(Pathfinder* pf, Node** a, Node** b) {
    Node* t = *a; *a = *b; *b = t;
    {
        int ia = cell_of(pf, *a)->pq_index;
        int ib = cell_of(pf, *b)->pq_index;
        cell_of(pf, *a)->pq_index = ib;
        cell_of(pf, *b)->pq_index = ia;
    }
}
/**
 * @brief 힙 위로 올리기(삽입 후 재정렬).
 * @param pf Pathfinder
 * @param pq 대상 큐
 * @param i 재정렬 시작 인덱스
 */
static void heapify_up(Pathfinder* pf, NodePQ* pq, int i) {
    if (i == 0) return;
    int p = (i - 1) / 2;
    if (compare_keys(key_of(pf, pq->nodes[i]), key_of(pf, pq->nodes[p])) < 0) {
        pq_swap(pf, &pq->nodes[i], &pq->nodes[p]);
        if (pf) pf->heap_moves_this_call++;  // 힙 이동 수 카운트
        heapify_up(pf, pq, p);
    }
}
/**
 * @brief 힙 아래로 내리기(루트 교체 후 재정렬).
 * @param pf Pathfinder
 * @param pq 대상 큐
 * @param i 재정렬 시작 인덱스
 */
static void heapify_down(Pathfinder* pf, NodePQ* pq, int i) {
    int l = 2 * i + 1, r = 2 * i + 2, s = i;
    if (l < pq->size && compare_keys(key_of(pf, pq->nodes[l]), key_of(pf, pq->nodes[s])) < 0) s = l;
    if (r < pq->size && compare_keys(key_of(pf, pq->nodes[r]), key_of(pf, pq->nodes[s])) < 0) s = r;
    if (s != i) {
        pq_swap(pf, &pq->nodes[i], &pq->nodes[s]);
        if (pf) pf->heap_moves_this_call++;  // 힙 이동 수 카운트
        heapify_down(pf, pq, s);
    }
}
/**
 * @brief 특정 노드가 큐에 포함되어 있는지 확인합니다.
 * @param pf Pathfinder
 * @param n 노드
 * @return 포함:1, 아니면 0
 */
static int pq_contains(Pathfinder* pf, const Node* n) { return cell_of(pf, n)->in_pq; }
/**
 * @brief 큐의 최상단 Key를 반환합니다. 비어있으면 (INF,INF).
 * @param pf Pathfinder
 * @param pq 대상 큐
 * @return 최상단 Key
 */
static Key pq_top_key(Pathfinder* pf, const NodePQ* pq) {
    if (pq->size == 0) return make_key(INF, INF);
    return key_of(pf, pq->nodes[0]);
}
/**
 * @brief 노드를 큐에 삽입합니다.
 * @param pf Pathfinder
 * @param pq 대상 큐
 * @param n 삽입할 노드
 */
static void pq_push(Pathfinder* pf, NodePQ* pq, Node* n) {
    if (pq->size >= pq->capacity) return;
    if (pf) pf->nodes_generated_this_call++;
    SearchCell* c = cell_of(pf, n);
    c->in_pq = TRUE; c->pq_index = pq->size; pq->nodes[pq->size++] = n;
    heapify_up(pf, pq, pq->size - 1);
}
/**
 * @brief 큐의 최상단 노드를 제거하고 반환합니다.
 * @param pf Pathfinder
 * @param pq 대상 큐
 * @return 팝된 노드 포인터 (없으면 NULL)
 */
static Node* pq_pop(Pathfinder* pf, NodePQ* pq) {
    if (pq->size == 0) return NULL;
    Node* top = pq->nodes[0];
    SearchCell* ct = cell_of(pf, top); ct->in_pq = FALSE; ct->pq_index = -1;
    pq->size--;
    if (pq->size > 0) {
        pq->nodes[0] = pq->nodes[pq->size];
        cell_of(pf, pq->nodes[0])->pq_index = 0;
        heapify_down(pf, pq, 0);
    }
    return top;
}
/**
 * @brief 큐에서 임의의 노드를 제거합니다.
 * @param pf Pathfinder
 * @param pq 대상 큐
 * @param n 제거할 노드
 */
static void pq_remove(Pathfinder* pf, NodePQ* pq, Node* n) {
    SearchCell* c = cell_of(pf, n); if (!c->in_pq) return;
    int idx = c->pq_index; pq->size--;
    if (idx != pq->size) {
        pq->nodes[idx] = pq->nodes[pq->size];
        cell_of(pf, pq->nodes[idx])->pq_index = idx;
        int parent = (idx - 1) / 2;
        if (idx > 0 && compare_keys(key_of(pf, pq->nodes[idx]), key_of(pf, pq->nodes[parent])) < 0)
            heapify_up(pf, pq, idx);
        else heapify_down(pf, pq, idx);
    }
    c->in_pq = FALSE; c->pq_index = -1;
}

// =============================================================================
// 섹션 8: 증분형 D* Lite 경로 탐색 알고리즘
// =============================================================================
/**
 * @brief 휴리스틱 함수(맨해튼 거리).
 * @param a 시작 노드
 * @param b 목표 노드
 * @return 맨해튼 거리
 */
static double heuristic(const Node* a, const Node* b) {
    return manhattan_nodes(a, b);
}
/**
 * @brief D* Lite의 키를 계산합니다.
 * @param pf Pathfinder
 * @param n 대상 노드
 * @return 계산된 Key
 */
static Key calculate_key(Pathfinder* pf, const Node* n) {
    SearchCell* c = cell_of(pf, n);
    double m = fmin(c->g, c->rhs);
    return make_key(m + heuristic(pf->start_node, n) + pf->km, m);
}
/**
 * @brief 한 노드의 rhs/g를 갱신하고 OPEN 리스트(힙)를 일관되게 유지합니다.
 * @param pf Pathfinder
 * @param map 그리드 맵
 * @param am 에이전트 매니저(점유/장애물 판단)
 * @param u 갱신할 노드
 */
static void updateVertex(Pathfinder* pf, GridMap* map, const AgentManager* am, Node* u) {
    SearchCell* cu = cell_of(pf, u);
    if (u != pf->goal_node) {
        double min_rhs = INF;
        for (int i = 0; i < DIR4_COUNT; i++) {
            int nx = u->x + DIR4_X[i], ny = u->y + DIR4_Y[i];
            if (!grid_is_valid_coord(nx, ny)) continue;
            Node* s = &map->grid[ny][nx];
            if (!grid_is_node_blocked(map, am, s, pf->agent)) {
                double gsucc = cell_of(pf, s)->g;
                double cand = 1.0 + gsucc;
                if (cand < min_rhs) min_rhs = cand;
            }
        }
        cu->rhs = min_rhs;
    }
    if (pq_contains(pf, u)) pq_remove(pf, &pf->pq, u);
    if (fabs(cu->g - cu->rhs) > 1e-9) {
        cu->key = calculate_key(pf, u);
        pq_push(pf, &pf->pq, u);
    }
}
/**
 * @brief Pathfinder 인스턴스를 생성하고 목표 노드를 OPEN 리스트에 삽입합니다.
 * @param start 시작 노드
 * @param goal 목표 노드
 * @return 생성된 Pathfinder 포인터
 */
Pathfinder* pathfinder_create(Node* start, Node* goal, const Agent* agent) {
    Pathfinder* pf = (Pathfinder*)calloc(1, sizeof(Pathfinder)); if (!pf) return NULL;
    pq_init(&pf->pq, GRID_WIDTH * GRID_HEIGHT);
    pf->start_node = start; pf->last_start = start; pf->goal_node = goal; pf->km = 0.0;
    pf->agent = agent;
    pf->nodes_expanded_this_call = 0;
    pf->heap_moves_this_call = 0;
    pf->nodes_generated_this_call = 0;
    pf->valid_expansions_this_call = 0;

    for (int y = 0; y < GRID_HEIGHT; y++)
        for (int x = 0; x < GRID_WIDTH; x++) {
            pf->cells[y][x].g = INF; pf->cells[y][x].rhs = INF;
            pf->cells[y][x].in_pq = FALSE; pf->cells[y][x].pq_index = -1;
            pf->cells[y][x].key = make_key(INF, INF);
        }

    if (goal) {
        SearchCell* cg = &pf->cells[goal->y][goal->x];
        cg->rhs = 0.0; cg->key = calculate_key(pf, goal);
        pq_push(pf, &pf->pq, goal);
    }
    return pf;
}
/**
 * @brief Pathfinder 리소스를 해제합니다.
 * @param pf 파괴할 Pathfinder
 */
void pathfinder_destroy(Pathfinder* pf) { if (pf) { pq_free(&pf->pq); free(pf); } }

/**
 * @brief 목표를 재설정하고 내부 상태(g/rhs/OPEN)를 초기화합니다.
 * @param pf Pathfinder
 * @param new_goal 새 목표 노드
 */
void pathfinder_reset_goal(Pathfinder* pf, Node* new_goal) {
    pf->goal_node = new_goal; pf->km = 0.0; pf->last_start = pf->start_node;
    pf->pq.size = 0;
    for (int y = 0; y < GRID_HEIGHT; y++)
        for (int x = 0; x < GRID_WIDTH; x++) {
            pf->cells[y][x].g = INF; pf->cells[y][x].rhs = INF;
            pf->cells[y][x].in_pq = FALSE; pf->cells[y][x].pq_index = -1;
            pf->cells[y][x].key = make_key(INF, INF);
        }
    if (new_goal) {
        pf->cells[new_goal->y][new_goal->x].rhs = 0.0;
        pf->cells[new_goal->y][new_goal->x].key = calculate_key(pf, new_goal);
        pq_push(pf, &pf->pq, new_goal);
    }
}
/**
 * @brief 시작 노드 변경을 Pathfinder에 알리고 km를 갱신합니다.
 * @param pf Pathfinder
 * @param new_start 새로운 시작 노드
 */
void pathfinder_update_start(Pathfinder* pf, Node* new_start) {
    if (new_start == NULL) return;
    if (pf->start_node == NULL) { pf->start_node = new_start; pf->last_start = new_start; return; }
    pf->km += heuristic(pf->last_start, new_start);
    pf->last_start = new_start;
    pf->start_node = new_start;
}
/**
 * @brief 셀 비용/점유 변화가 발생했음을 Pathfinder에 통지하여 관련 노드를 갱신합니다.
 * @param pf Pathfinder
 * @param map 그리드 맵
 * @param am 에이전트 매니저
 * @param changed 변경된 노드
 */
void pathfinder_notify_cell_change(Pathfinder* pf, GridMap* map, const AgentManager* am, Node* changed) {
    updateVertex(pf, map, am, changed);
    for (int i = 0; i < DIR4_COUNT; i++) {
        int px = changed->x + DIR4_X[i], py = changed->y + DIR4_Y[i];
        if (grid_is_valid_coord(px, py)) updateVertex(pf, map, am, &map->grid[py][px]);
    }
}
/**
 * @brief D* Lite 최단 경로를 증분적으로 계산합니다.
 * @param pf Pathfinder
 * @param map 그리드 맵
 * @param am 에이전트 매니저
 */
void pathfinder_compute_shortest_path(Pathfinder* pf, GridMap* map, const AgentManager* am) {
    if (!pf->start_node || !pf->goal_node) return;

    // 메트릭 초기화 (이전 값 유지하지 않고 새로 시작)
    pf->nodes_expanded_this_call = 0;
    pf->heap_moves_this_call = 0;

    while (TRUE) {
        Key top = pq_top_key(pf, &pf->pq);
        SearchCell* cs = cell_of(pf, pf->start_node);
        Key kstart = calculate_key(pf, pf->start_node);

        if (pf->pq.size == 0 || (compare_keys(top, kstart) >= 0 && fabs(cs->rhs - cs->g) < 1e-9)) break;

        Key k_old = top;
        Node* u = pq_pop(pf, &pf->pq);
        if (u) pf->nodes_expanded_this_call++;  // 노드 확장 수 카운트
        SearchCell* cu = cell_of(pf, u);
        Key k_new = calculate_key(pf, u);

        if (compare_keys(k_old, k_new) < 0) {
            cu->key = k_new;
            pq_push(pf, &pf->pq, u);
        }
        else if (cu->g > cu->rhs) {
            cu->g = cu->rhs;
            pf->valid_expansions_this_call++;
            for (int i = 0; i < DIR4_COUNT; i++) {
                int px = u->x + DIR4_X[i], py = u->y + DIR4_Y[i];
                if (grid_is_valid_coord(px, py))
                    updateVertex(pf, map, am, &map->grid[py][px]);
            }
        }
        else {
            cu->g = INF;
            updateVertex(pf, map, am, u);
            for (int i = 0; i < DIR4_COUNT; i++) {
                int px = u->x + DIR4_X[i], py = u->y + DIR4_Y[i];
                if (grid_is_valid_coord(px, py))
                    updateVertex(pf, map, am, &map->grid[py][px]);
            }
        }
    }
}
/**
 * @brief 현재 노드에서 다음 스텝으로 가장 좋은 이웃을 반환합니다.
 *        동률일 경우 목표에 더 가까운(맨해튼) 이웃을 선택합니다.
 * @param pf Pathfinder
 * @param map 그리드 맵
 * @param am 에이전트 매니저
 * @param current 현재 노드
 * @return 다음 스텝 노드(없으면 current)
 */
Node* pathfinder_get_next_step(Pathfinder* pf, const GridMap* map, const AgentManager* am, Node* current) {
    if (!pf->goal_node || !current) return current;
    SearchCell* cc = cell_of(pf, current);
    if (cc->g >= INF || current == pf->goal_node) return current;

    double best = INF; Node* bestn = current;
    double tie_euclid = fabs((double)current->x - (double)pf->goal_node->x) + fabs((double)current->y - (double)pf->goal_node->y);

    for (int i = 0; i < DIR4_COUNT; i++) {
        int nx = current->x + DIR4_X[i], ny = current->y + DIR4_Y[i];
        if (!grid_is_valid_coord(nx, ny)) continue;
        Node* nb = &((GridMap*)map)->grid[ny][nx];
        if (grid_is_node_blocked(map, am, nb, pf->agent)) continue;
        double gsucc = cell_of(pf, nb)->g;
        double cost = 1.0 + gsucc;
        if (cost < best) {
            best = cost; bestn = nb;
            tie_euclid = manhattan_nodes(nb, pf->goal_node);
        }
        else if (fabs(cost - best) < 1e-9) {
            double d = manhattan_nodes(nb, pf->goal_node);
            if (d < tie_euclid) { bestn = nb; tie_euclid = d; }
        }
    }
    return bestn;
}

// =============================================================================
// 섹션 9: 경로 계획 및 충돌 회피 (WHCA* + WFG/SCC + Partial CBS)
// =============================================================================
static void ReservationTable_clear(ReservationTable* r) {
    for (int t = 0; t <= MAX_WHCA_HORIZON; t++)
        for (int y = 0; y < GRID_HEIGHT; y++)
            for (int x = 0; x < GRID_WIDTH; x++)
                r->occ[t][y][x] = -1;
}
/**
 * @brief 시간 t=0에 현재 에이전트들의 위치를 예약 테이블에 씨드합니다.
 * @param r 예약 테이블
 * @param m 에이전트 매니저
 */
static void ReservationTable_seedCurrent(ReservationTable* r, AgentManager* m) {
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &m->agents[i];
        if (ag->pos && ag->state != CHARGING) r->occ[0][ag->pos->y][ag->pos->x] = ag->id;
    }
}
/**
 * @brief 시각 t에서 노드 n이 이미 예약되었는지 확인합니다.
 * @param r 예약 테이블
 * @param t 시간 (1..H)
 * @param n 노드
 * @return 점유됨:1, 아니면 0
 */
static int ReservationTable_isOccupied(const ReservationTable* r, int t, const Node* n) {
    if (t < 0 || t > g_whca_horizon) return TRUE;
    return r->occ[t][n->y][n->x] != -1;
}
/**
 * @brief 예약 테이블에서 해당 시각/노드의 점유 에이전트 ID를 반환합니다.
 * @param r 예약 테이블
 * @param t 시간
 * @param n 노드
 * @return 에이전트 ID, 없으면 -1
 */
static int ReservationTable_getOccupant(const ReservationTable* r, int t, const Node* n) {
    if (t < 0 || t > g_whca_horizon) return -1;
    return r->occ[t][n->y][n->x];
}
/**
 * @brief 예약 테이블에 점유자를 설정합니다.
 * @param r 예약 테이블
 * @param t 시간
 * @param n 노드
 * @param agent_id 에이전트 ID
 */
static void ReservationTable_setOccupant(ReservationTable* r, int t, const Node* n, int agent_id) {
    if (t < 0 || t > g_whca_horizon) return;
    r->occ[t][n->y][n->x] = agent_id;
}

AgentManager* agent_manager_create() {
    /**
     * @brief 에이전트 매니저를 생성하고 모든 에이전트 필드를 초기화합니다.
     * @return 생성된 AgentManager 포인터
     */
    AgentManager* m = (AgentManager*)calloc(1, sizeof(AgentManager));
    if (!m) { perror("AgentManager"); exit(1); }
    for (int i = 0; i < MAX_AGENTS; i++) {
        m->agents[i].id = i;
        m->agents[i].symbol = 'A' + i;
        m->agents[i].state = IDLE;
        m->agents[i].heading = DIR_NONE;
        m->agents[i].rotation_wait = 0;
        m->agents[i].action_timer = 0;
        m->agents[i].pf = NULL;
        m->agents[i].stuck_steps = 0;
        m->agents[i].metrics_task_active = 0;
        m->agents[i].metrics_task_start_step = 0;
        m->agents[i].metrics_distance_at_start = 0.0;
        m->agents[i].metrics_turns_current = 0;
    }
    return m;
}
/**
 * @brief 에이전트 매니저와 각 에이전트의 Pathfinder를 해제합니다.
 * @param m 파괴할 AgentManager
 */
void agent_manager_destroy(AgentManager* m) {
    if (m) {
        for (int i = 0; i < MAX_AGENTS; i++) if (m->agents[i].pf) pathfinder_destroy(m->agents[i].pf);
        free(m);
    }
}

// =============================================================================
// Agent OO-like wrappers (semantics-preserving; use existing logging/metrics)
// =============================================================================
void agent_begin_task_park(Agent* ag, ScenarioManager* sc, Logger* lg) {
    /**
     * @brief 에이전트 주차 작업을 시작하고 메트릭을 초기화합니다.
     * @param ag 에이전트
     * @param sc 시나리오 매니저
     * @param lg 로거
     */
    if (!ag || !sc) return;
    ag->state = GOING_TO_PARK;
    ag->metrics_task_active = 1;
    ag->metrics_task_start_step = sc->time_step;
    ag->metrics_distance_at_start = ag->total_distance_traveled;
    ag->metrics_turns_current = 0;
    if (lg) logger_log(lg, "[%sTask%s] Agent %c, 신규 주차 작업 할당.", C_CYN, C_NRM, ag->symbol);
}
void agent_begin_task_exit(Agent* ag, ScenarioManager* sc, Logger* lg) {
    /**
     * @brief 에이전트 출차 작업을 시작하고 메트릭을 초기화합니다.
     * @param ag 에이전트
     * @param sc 시나리오 매니저
     * @param lg 로거
     */
    if (!ag || !sc) return;
    ag->state = GOING_TO_COLLECT;
    ag->metrics_task_active = 1;
    ag->metrics_task_start_step = sc->time_step;
    ag->metrics_distance_at_start = ag->total_distance_traveled;
    ag->metrics_turns_current = 0;
    if (lg) logger_log(lg, "[%sTask%s] Agent %c, 신규 출차 작업 할당.", C_CYN, C_NRM, ag->symbol);
}

static double calculate_path_cost_tempPF(Agent* ag, Node* goal, GridMap* map, AgentManager* am)
{
    /**
     * @brief 임시 Pathfinder를 만들어 현재 위치→goal의 경로 비용을 추정합니다.
     * @param ag 에이전트
     * @param goal 목표 노드
     * @param map 그리드 맵
     * @param am 에이전트 매니저
     * @return 경로 비용(도달 불가 시 INF)
     */
     // 안전 가드: 배치 전이거나 목표/맵이 없으면 경로 불가로 처리
    if (!ag || !ag->pos || !goal || !map || !am) return INF;

    // 현재 위치가 곧 목표면 비용 0
    if (ag->pos == goal) return 0.0;

    // 하드 블록(벽) 목표는 바로 배제
    if (goal->is_obstacle) return INF;

    Pathfinder* pf = pathfinder_create(ag->pos, goal, ag);
    if (!pf) return INF;

    pathfinder_compute_shortest_path(pf, map, am);
    double cost = cell_of(pf, ag->pos)->g;

    pathfinder_destroy(pf);

    // 도달 불가 시 INF 유지
    if (cost >= INF * 0.5) return INF;
    return cost;
}

// 공통 선택 헬퍼: 후보 리스트에서 경로 비용이 최소인 노드를 선택
// require_parked: -1=무시, 0=비주차칸만, 1=주차칸만
// check_reserved: 1이면 타 에이전트 예약 칸 제외
// toggle_parked_during_eval: 비용 평가 중 일시적으로 is_parked를 뒤집어 경로성 평가(출차용)
// 선택 로직 공통 헬퍼
// - 후보 중 경로 비용 최소 노드 선택
// - require_parked: -1=무시, 0=비주차, 1=주차만
// - check_reserved: 타 에이전트 예약 제외 여부
// - toggle_parked_during_eval: 평가 동안 is_parked 일시 해제(출차용)
static Node* select_best_from_list(Agent* ag, GridMap* map, AgentManager* am,
    Node** list, int count, int require_parked, int check_reserved, int toggle_parked_during_eval, double* out_best_cost)
{
    /**
     * @brief 후보 노드 리스트에서 경로 비용이 최소인 노드를 선택합니다.
     * @param ag 에이전트
     * @param map 그리드 맵
     * @param am 에이전트 매니저
     * @param list 후보 노드 배열
     * @param count 후보 수
     * @param require_parked -1=무시, 0=비주차, 1=주차만
     * @param check_reserved 타 에이전트 예약 제외 여부(1=제외)
     * @param toggle_parked_during_eval 평가 중 일시적으로 is_parked 해제 여부(출차 선택용)
     * @param out_best_cost 선택된 비용 반환 포인터(선택)
     * @return 최적 노드(없으면 NULL)
     */
    double best = INF; Node* bestn = NULL;
    for (int j = 0; j < count; j++) {
        Node* n = list[j]; if (!n) continue;
        if (require_parked == 1 && !n->is_parked) continue;
        if (require_parked == 0 && n->is_parked) continue;
        if (check_reserved && (n->reserved_by_agent != -1 && n->reserved_by_agent != ag->id)) continue;

        int restored = 0;
        if (toggle_parked_during_eval && n->is_parked) { n->is_parked = FALSE; restored = 1; }
        double c = calculate_path_cost_tempPF(ag, n, map, am);
        if (restored) n->is_parked = TRUE;

        if (c < best) { best = c; bestn = n; }
    }
    if (out_best_cost) *out_best_cost = best;
    return bestn;
}

// 통합 목표 선택 타입과 헬퍼
typedef enum { GOAL_PARKING, GOAL_PARKED_CAR, GOAL_CHARGE } GoalType;

static Node* select_best_goal(Agent* ag, GridMap* map, AgentManager* am, Logger* lg, GoalType type, double* out_cost) {
    /**
     * @brief 목표 유형별(GOAL_PARKING/GOAL_PARKED_CAR/GOAL_CHARGE) 최적 노드를 선택합니다.
     * @param ag 에이전트
     * @param map 그리드 맵
     * @param am 에이전트 매니저
     * @param lg 로거
     * @param type 목표 유형
     * @param out_cost 선택 비용 반환 포인터(선택)
     * @return 최적 목표 노드
     */
    Node** list = NULL; int count = 0; int require_parked = -1; int check_reserved = 1; int toggle_parked = 0;
    switch (type) {
    case GOAL_PARKING:
        list = map->goals; count = map->num_goals; require_parked = 0; toggle_parked = 0; break;
    case GOAL_PARKED_CAR:
        list = map->goals; count = map->num_goals; require_parked = 1; toggle_parked = 1; break;
    case GOAL_CHARGE:
        list = map->charge_stations; count = map->num_charge_stations; require_parked = -1; toggle_parked = 0; break;
    }
    return select_best_from_list(ag, map, am, list, count, require_parked, check_reserved, toggle_parked, out_cost);
}

static Node* select_best_parking_spot(Agent* ag, GridMap* map, AgentManager* am, Logger* lg) {
    /**
     * @brief 주차 가능한 최적 위치를 선택합니다.
     * @return 선택된 노드(없으면 NULL)
     */
    double best_cost = INF;
    Node* bestg = select_best_goal(ag, map, am, lg, GOAL_PARKING, &best_cost);
    if (bestg) logger_log(lg, "[%sPlan%s] Agent %c, 주차 공간 (%d,%d) 선택 (비용: %.1f)",
        C_CYN, C_NRM, ag->symbol, bestg->x, bestg->y, best_cost);
    return bestg;
}
static Node* select_best_parked_car(Agent* ag, GridMap* map, AgentManager* am, Logger* lg) {
    /**
     * @brief 출차 대상(주차된 차량) 중 최적 위치를 선택합니다.
     * @return 선택된 노드(없으면 NULL)
     */
    double best_cost = INF;
    Node* bests = select_best_goal(ag, map, am, lg, GOAL_PARKED_CAR, &best_cost);
    if (bests) logger_log(lg, "[%sPlan%s] Agent %c, 출차 차량 (%d,%d) 선택 (비용: %.1f)",
        C_CYN, C_NRM, ag->symbol, bests->x, bests->y, best_cost);
    return bests;
}
static Node* select_best_charge_station(Agent* ag, GridMap* map, AgentManager* am, Logger* lg) {
    /**
     * @brief 사용 가능한 최적 충전소를 선택합니다.
     * @return 선택된 충전소 노드(없으면 NULL)
     */
    double best_cost = INF;
    Node* bests = select_best_goal(ag, map, am, lg, GOAL_CHARGE, &best_cost);
    if (bests) logger_log(lg, "[%sPlan%s] Agent %c, 충전소 (%d,%d) 선택 (비용: %.1f)",
        C_CYN, C_NRM, ag->symbol, bests->x, bests->y, best_cost);
    return bests;
}
static void ensure_pathfinder_for_agent(Agent* ag) {
    /**
     * @brief 에이전트에 Pathfinder가 없으면 생성하고, 목표 변경 시 재설정합니다.
     * @param ag 에이전트
     */
    if (!ag->goal) return;
    if (ag->pf == NULL) {
        ag->pf = pathfinder_create(ag->pos, ag->goal, ag);
    }
    else if (ag->pf->goal_node != ag->goal) {
        ag->pf->start_node = ag->pos;
        pathfinder_reset_goal(ag->pf, ag->goal);
    }
}

// priority score
static int priority_score(const Agent* ag) {
    /**
     * @brief 에이전트 상태와 stuck 정도로 우선순위 점수를 계산합니다.
     * @param ag 에이전트
     * @return 높은 값일수록 높은 우선순위
     */
    int imp = 0;
    if (ag->state == RETURNING_WITH_CAR) imp = PRIORITY_RETURNING_WITH_CAR;
    else if (ag->state == GOING_TO_CHARGE) imp = PRIORITY_GOING_TO_CHARGE;
    else if (ag->state == GOING_TO_PARK || ag->state == GOING_TO_COLLECT) imp = PRIORITY_MOVING_TASK;

    {
        int stuck_boost = (ag->stuck_steps >= DEADLOCK_THRESHOLD) ? STUCK_BOOST_HARD : (ag->stuck_steps * STUCK_BOOST_MULT);
        return imp * 100 + stuck_boost - ag->id;
    }
}
static void sort_agents_by_priority(AgentManager* m, int order[MAX_AGENTS]) {
    /**
     * @brief 우선순위 점수에 따라 에이전트 인덱스 배열을 내림차순 정렬합니다.
     * @param m 에이전트 매니저
     * @param order 정렬 결과(인덱스) 출력 배열
     */
    for (int i = 0; i < MAX_AGENTS; i++) order[i] = i;
    for (int i = 0; i < MAX_AGENTS; i++)
        for (int j = i + 1; j < MAX_AGENTS; j++)
            if (priority_score(&m->agents[order[j]]) > priority_score(&m->agents[order[i]])) {
                int t = order[i]; order[i] = order[j]; order[j] = t;
            }
}
static void agent_set_goal(Agent* ag, GridMap* map, AgentManager* am, Logger* lg)
{
    /**
     * @brief 에이전트 상태에 따라 적절한 목표(주차칸/출차칸/충전소/기지)를 설정합니다.
     *        필요시 이전 예약을 해제하고, 목표 예약을 설정합니다.
     * @param ag 에이전트
     * @param map 그리드 맵
     * @param am 에이전트 매니저
     * @param lg 로거
     */
     // 0) 배치되지 않은 에이전트는 아무 것도 하지 않음(크래시 방지)
    if (!ag || !ag->pos) {
        ag->goal = NULL;
        ag->state = IDLE;
        return;
    }

    // 1) 충전 임계치 도달 시 상태 전환
    if (ag->state == RETURNING_HOME_EMPTY &&
        ag->total_distance_traveled >= DISTANCE_BEFORE_CHARGE) {
        if (ag->goal) { ag->goal->reserved_by_agent = -1; ag->goal = NULL; }
        logger_log(lg, "[%sCharge%s] Agent %c 충전 필요! 목표를 충전소로 전환.", C_B_YEL, C_NRM, ag->symbol);
        ag->state = GOING_TO_CHARGE;
    }

    // 2) 이미 목표가 있거나, 대기/충전 중이면 종료
    if (ag->state == IDLE || ag->state == CHARGING || ag->goal) return;

    // 3) 상태별 목표 선택
    Node* new_goal = NULL;
    switch (ag->state) {
    case GOING_TO_PARK:
        new_goal = select_best_parking_spot(ag, map, am, lg);
        break;
    case RETURNING_HOME_EMPTY:
    case RETURNING_WITH_CAR:
    case RETURNING_HOME_MAINTENANCE:
        new_goal = ag->home_base;
        break;
    case GOING_TO_COLLECT:
        new_goal = select_best_parked_car(ag, map, am, lg);
        break;
    case GOING_TO_CHARGE:
        new_goal = select_best_charge_station(ag, map, am, lg);
        break;
    default:
        break;
    }

    // 4) 목표 적용/실패 처리
    if (new_goal) {
        // (필요시 이전 예약 해제 - 충전 전환 때는 위에서 이미 해제)
        if (ag->goal && ag->goal != new_goal) ag->goal->reserved_by_agent = -1;

        ag->goal = new_goal;
        ag->goal->reserved_by_agent = ag->id;  // 점유 예약(충전소 포함)
    }
    else {
        // 목표를 못 잡은 경우 안전하게 대기 전환 (귀환 상태는 예외적으로 home_base 부재 시만 대기)
        if (ag->state == RETURNING_HOME_EMPTY ||
            ag->state == RETURNING_WITH_CAR ||
            ag->state == RETURNING_HOME_MAINTENANCE) {
            if (!ag->home_base) {
                ag->state = IDLE;
                logger_log(lg, "[%sWarn%s] Agent %c: 홈 베이스가 없어 대기 상태로 전환.", C_B_RED, C_NRM, ag->symbol);
            }
        }
        else {
            ag->state = IDLE;
            logger_log(lg, "[%sInfo%s] Agent %c: 가용 목표 없음. 대기.", C_YEL, C_NRM, ag->symbol);
        }
    }
}

static int best_candidate_order(Pathfinder* pf, const GridMap* map, const AgentManager* am,
    Node* cur, Node* goal, Node* out[5], int* outN) {
    /**
     * @brief 현재 위치에서 후보(정지+4방)들을 비용/휴리스틱 기준으로 정렬합니다.
     * @param pf Pathfinder
     * @param map 그리드 맵
     * @param am 에이전트 매니저
     * @param cur 현재 노드
     * @param goal 목표 노드
     * @param out 정렬된 후보 노드 배열(STAY 포함)
     * @param outN 후보 수 출력
     * @return 후보 수
     */
    typedef struct { Node* n; double cost; double d; } Cand;
    Cand cands[5]; int cn = 0;

    double gcur = cell_of(pf, cur)->g;
    cands[cn++] = (Cand){ cur, gcur + 1e-6, 1e18 };

    for (int k = 0; k < DIR4_COUNT; k++) {
        int nx = cur->x + DIR4_X[k], ny = cur->y + DIR4_Y[k];
        if (!grid_is_valid_coord(nx, ny)) continue;
        Node* nb = &((GridMap*)map)->grid[ny][nx];
        if (grid_is_node_blocked(map, am, nb, pf->agent)) continue;
        double gsucc = cell_of(pf, nb)->g;
        double cost = 1.0 + gsucc;
        double d = manhattan_nodes(nb, goal);
        cands[cn++] = (Cand){ nb, cost, d };
    }
    for (int a = 0; a < cn; a++) for (int b = a + 1; b < cn; b++) {
        if (cands[b].cost < cands[a].cost || (fabs(cands[b].cost - cands[a].cost) < 1e-9 && cands[b].d < cands[a].d)) {
            Cand t = cands[a]; cands[a] = cands[b]; cands[b] = t;
        }
    }
    for (int i = 0; i < cn; i++) out[i] = cands[i].n;
    *outN = cn;
    return cn;
}

// ---- WFG helpers ----
static void add_wait_edge(WaitEdge* edges, int* cnt, int from, int to, int t, CauseType cause, int x1, int y1, int x2, int y2) {
    /**
     * @brief 대기 그래프에 에지를 추가합니다(정점/스왑 충돌 정보 포함).
     * @param edges 에지 배열
     * @param cnt 현재 개수(추가되면 증가)
     * @param from 대기하는 에이전트 ID
     * @param to 상대 에이전트 ID
     * @param t 충돌 시간(1..H)
     * @param cause 원인(CAUSE_VERTEX/CAUSE_SWAP)
     * @param x1,y1 위치 정보1
     * @param x2,y2 위치 정보2(스왑 시 사용)
     */
    if (*cnt >= MAX_WAIT_EDGES) return;
    edges[*cnt].from_id = from; edges[*cnt].to_id = to; edges[*cnt].t = t;
    edges[*cnt].cause = cause; edges[*cnt].x1 = x1; edges[*cnt].y1 = y1; edges[*cnt].x2 = x2; edges[*cnt].y2 = y2;
    (*cnt)++;
}
static int build_scc_mask_from_edges(const WaitEdge* edges, int cnt) {
    /**
     * @brief 대기 그래프에서 SCC(강연결요소) 존재 여부를 마스크로 반환합니다.
     * @param edges 에지 배열
     * @param cnt 에지 수
     * @return SCC에 포함된 에이전트 비트마스크(없으면 0)
     */
    int adj[MAX_AGENTS][MAX_AGENTS] = { 0 };
    for (int i = 0; i < cnt; i++) {
        int u = edges[i].from_id, v = edges[i].to_id;
        if (u >= 0 && v >= 0 && u != v) adj[u][v] = 1;
    }
    int reach[MAX_AGENTS][MAX_AGENTS] = { 0 };
    for (int i = 0; i < MAX_AGENTS; i++)
        for (int j = 0; j < MAX_AGENTS; j++) reach[i][j] = adj[i][j];
    for (int k = 0; k < MAX_AGENTS; k++)
        for (int i = 0; i < MAX_AGENTS; i++)
            for (int j = 0; j < MAX_AGENTS; j++)
                reach[i][j] = reach[i][j] || (reach[i][k] && reach[k][j]);

    {
        int mask = 0;
        for (int i = 0; i < MAX_AGENTS; i++)
            for (int j = 0; j < MAX_AGENTS; j++)
                if (i != j && reach[i][j] && reach[j][i]) { mask |= (1 << i); mask |= (1 << j); }
        return mask;
    }
}

// ---- pull-over(대피) 후보 한 칸 찾기 ----
static Node* try_pull_over(const GridMap* map, const ReservationTable* rt, Agent* ag) {
    /**
     * @brief 한 틱 동안 비어있는 인접 셀(정지 포함)로 비켜서기 위치를 탐색합니다.
     * @param map 그리드 맵
     * @param rt 예약 테이블
     * @param ag 에이전트
     * @return 가능하면 대피 위치, 불가 시 현재 위치
     */
    for (int k = 0; k < DIR5_COUNT; k++) {
        int nx = ag->pos->x + DIR5_X[k], ny = ag->pos->y + DIR5_Y[k];
        if (!grid_is_valid_coord(nx, ny)) continue;
        Node* nb = (Node*)&map->grid[ny][nx];
        if (nb == ag->pos) { if (!ReservationTable_isOccupied(rt, 1, nb)) return nb; else continue; }
        if (nb->is_obstacle || nb->is_parked) continue;
        // 타 에이전트가 예약한 주차칸은 대피 후보에서 제외
        if (nb->reserved_by_agent != -1 && nb->reserved_by_agent != ag->id) continue;
        if (!ReservationTable_isOccupied(rt, 1, nb)) return nb;
    }
    return ag->pos;
}

// priority helper
static int best_in_mask(const AgentManager* m, int mask) {
    /**
     * @brief 마스크에 포함된 에이전트 중 우선순위가 가장 높은 ID를 반환합니다.
     * @param m 에이전트 매니저
     * @param mask 비트마스크
     * @return 최고 우선순위 에이전트 ID(없으면 -1)
     */
    int best = -1, bestScore = -999999;
    for (int i = 0; i < MAX_AGENTS; i++) if (mask & (1 << i)) {
        int sc = priority_score(&m->agents[i]);
        if (sc > bestScore) { bestScore = sc; best = i; }
    }
    return best;
}

// ---- Partial-team CBS: low-level ST-A* ----
static double G_buf[MAX_TOT], F_buf[MAX_TOT];
static unsigned char OPEN_buf[MAX_TOT], CLOSED_buf[MAX_TOT];
static int PREV_buf[MAX_TOT];
static int HEAP_NODE_buf[MAX_TOT];
static int HEAP_POS_buf[MAX_TOT];

static int heap_prefer(double* fvals, int a, int b) {
    double fa = fvals[a];
    double fb = fvals[b];
    if (fa < fb - 1e-9) return 1;
    if (fa > fb + 1e-9) return 0;
    return a < b;
}

static void heap_swap(int* nodes, int* pos, int i, int j, unsigned long long* swap_counter) {
    if (i == j) return;
    int ni = nodes[i];
    int nj = nodes[j];
    nodes[i] = nj;
    nodes[j] = ni;
    pos[nj] = i;
    pos[ni] = j;
    if (swap_counter) (*swap_counter)++;
}

static void heap_sift_up(int* nodes, int* pos, double* fvals, int idx, unsigned long long* swap_counter) {
    while (idx > 0) {
        int parent = (idx - 1) >> 1;
        if (!heap_prefer(fvals, nodes[idx], nodes[parent])) break;
        heap_swap(nodes, pos, idx, parent, swap_counter);
        idx = parent;
    }
}

static void heap_sift_down(int* nodes, int* pos, double* fvals, int size, int idx, unsigned long long* swap_counter) {
    while (1) {
        int left = (idx << 1) + 1;
        int right = left + 1;
        int best = idx;
        if (left < size && heap_prefer(fvals, nodes[left], nodes[best])) best = left;
        if (right < size && heap_prefer(fvals, nodes[right], nodes[best])) best = right;
        if (best == idx) break;
        heap_swap(nodes, pos, idx, best, swap_counter);
        idx = best;
    }
}

static void heap_push(int* nodes, int* pos, double* fvals, int* size, int node, unsigned long long* swap_counter) {
    nodes[*size] = node;
    pos[node] = *size;
    (*size)++;
    heap_sift_up(nodes, pos, fvals, (*size) - 1, swap_counter);
}

static int heap_pop(int* nodes, int* pos, double* fvals, int* size, unsigned long long* swap_counter) {
    if (*size == 0) return -1;
    int root = nodes[0];
    (*size)--;
    if (*size > 0) {
        int last = nodes[*size];
        nodes[0] = last;
        pos[last] = 0;
        heap_sift_down(nodes, pos, fvals, *size, 0, swap_counter);
    }
    pos[root] = -1;
    return root;
}

static void heap_decrease_key(int* nodes, int* pos, double* fvals, int node, unsigned long long* swap_counter) {
    int idx = pos[node];
    if (idx >= 0) {
        heap_sift_up(nodes, pos, fvals, idx, swap_counter);
    }
}

static int violates_constraint_for(int agent, int t_prev, int x_prev, int y_prev, int x_new, int y_new,
    const CBSConstraint* cons, int ncons) {
    /**
     * @brief 주어진 이동이 CBS 제약 조건을 위반하는지 검사합니다.
     * @param agent 에이전트 ID
     * @param t_prev 이전 시간
     * @param x_prev,y_prev 이전 위치
     * @param x_new,y_new 새 위치
     * @param cons 제약 배열
     * @param ncons 제약 수
     * @return 위반:1, 아니면 0
     */
    for (int i = 0; i < ncons; i++) {
        if (cons[i].agent != agent) continue;
        if (cons[i].is_edge) {
            if (cons[i].t == t_prev && cons[i].x == x_prev && cons[i].y == y_prev &&
                cons[i].tox == x_new && cons[i].toy == y_new) return 1;
        }
        else {
            if (cons[i].t == (t_prev + 1) && cons[i].x == x_new && cons[i].y == y_new) return 1;
        }
    }
    return 0;
}
static int st_astar_plan_single(int agent_id, GridMap* map, Node* start, Node* goal, int horizon,
    int ext_occ[MAX_WHCA_HORIZON + 1][GRID_HEIGHT][GRID_WIDTH],
    const CBSConstraint* cons, int ncons,
    Node* out_plan[MAX_WHCA_HORIZON + 1],
    AgentDir initial_heading,
    unsigned long long* out_nodes_expanded,
    unsigned long long* out_heap_moves,
    unsigned long long* out_generated_nodes,
    unsigned long long* out_valid_expansions) {
    /**
     * @brief 시간-공간 A*로 단일 에이전트의 호라이즌 내 계획을 수립합니다.
     *        정지 이동 포함(STAY), 외부 예약/제약을 고려합니다.
     * @param agent_id 에이전트 ID
     * @param map 그리드 맵
     * @param start 시작 노드
     * @param goal 목표 노드(없으면 호라이즌 내 최적 위치)
     * @param horizon WHCA* 호라이즌
     * @param ext_occ 외부 점유 테이블(다른 에이전트)
     * @param cons CBS 제약 배열
     * @param ncons 제약 수
     * @param out_plan t=0..H 경로 출력 배열
     * @return 성공:1, 실패:0
     */
    if (!start) return 0;
    int T = horizon;
    int W = GRID_WIDTH, H = GRID_HEIGHT;
    int TOT = (T + 1) * W * H;
    if (out_nodes_expanded) *out_nodes_expanded = 0;
    if (out_heap_moves) *out_heap_moves = 0;
    if (out_generated_nodes) *out_generated_nodes = 0;
    if (out_valid_expansions) *out_valid_expansions = 0;
    if (TOT > MAX_TOT) return 0;

    double* g = G_buf;
    double* f = F_buf;
    unsigned char* open = OPEN_buf;
    unsigned char* closed = CLOSED_buf;
    int* prev = PREV_buf;
    int* heap_nodes = HEAP_NODE_buf;
    int* heap_pos = HEAP_POS_buf;
    int heap_size = 0;

    for (int i = 0; i < TOT; i++) {
        g[i] = INF;
        f[i] = INF;
        open[i] = 0;
        closed[i] = 0;
        prev[i] = -1;
        heap_pos[i] = -1;
    }

#ifndef ST_INDEX
#define ST_INDEX(t,y,x,width,height) ((t)*(width)*(height) + (y)*(width) + (x))
#endif

    int sx = start->x, sy = start->y;
    int gx = goal ? goal->x : sx, gy = goal ? goal->y : sy;

    int start_idx = ST_INDEX(0, sy, sx, W, H);
    g[start_idx] = 0.0;
    f[start_idx] = goal ? manhattan_xy(sx, sy, gx, gy) : 0.0;
    open[start_idx] = 1;

    int best_idx = start_idx; double best_val = f[start_idx];
    unsigned long long nodes_expanded = 0;
    unsigned long long heap_moves = 0;
    unsigned long long generated_nodes = 0;
    unsigned long long valid_expansions = 0;

    heap_push(heap_nodes, heap_pos, f, &heap_size, start_idx, &heap_moves);

    while (heap_size > 0) {
        int cur = heap_pop(heap_nodes, heap_pos, f, &heap_size, &heap_moves);
        double curF = f[cur];
        open[cur] = 0;
        closed[cur] = 1;
        nodes_expanded++;

        int ct = cur / (W * H);
        int rem = cur % (W * H);
        int cy = rem / W, cx = rem % W;

        if (goal && cx == gx && cy == gy) {
            best_idx = cur; break;
        }
        if (f[cur] < best_val) { best_val = f[cur]; best_idx = cur; }

        if (ct == T) continue;

        for (int k = 0; k < DIR5_COUNT; k++) {
            int nx = cx + DIR5_X[k], ny = cy + DIR5_Y[k];
            int nt = ct + 1;
            if (!grid_is_valid_coord(nx, ny)) continue;

            if (ext_occ[nt][ny][nx] != -1) continue;

            if (ext_occ[ct][ny][nx] != -1 && ext_occ[nt][cy][cx] == ext_occ[ct][ny][nx]) continue;

            Node* ncell = &map->grid[ny][nx];
            if (ncell->is_obstacle) continue;

            if (violates_constraint_for(agent_id, ct, cx, cy, nx, ny, cons, ncons)) continue;

            int nid = ST_INDEX(nt, ny, nx, W, H);
            if (closed[nid]) continue;
            generated_nodes++;
            {
                double ng = g[cur] + 1.0;
                // 회전 딜레이 비용을 초기 이동(ct==0)에서 가중치로 반영
                if (ct == 0 && !(nx == cx && ny == cy)) {
                    AgentDir move_heading = dir_from_delta(nx - cx, ny - cy);
                    if (initial_heading != DIR_NONE) {
                        int tsteps = dir_turn_steps(initial_heading, move_heading);
                        if (tsteps == 1) {
                            ng += (double)TURN_90_WAIT; // 90도 회전 가중치
                        }
                    }
                }
                if (ng + 1e-9 < g[nid]) {
                    g[nid] = ng;
                    double h = goal ? manhattan_xy(nx, ny, gx, gy) : 0.0;
                    f[nid] = ng + h;
                    prev[nid] = cur;
                    if (!open[nid]) {
                        open[nid] = 1;
                        heap_push(heap_nodes, heap_pos, f, &heap_size, nid, &heap_moves);
                    }
                    else {
                        heap_decrease_key(heap_nodes, heap_pos, f, nid, &heap_moves);
                    }
                    valid_expansions++;
                }
            }
        }
    }

    int path_idx[MAX_WHCA_HORIZON + 1]; int plen = 0;
    {
        int cur = best_idx;
        while (cur != -1 && plen < (MAX_WHCA_HORIZON + 1)) { path_idx[plen++] = cur; cur = prev[cur]; }
    }
    if (out_nodes_expanded) *out_nodes_expanded = nodes_expanded;
    if (out_heap_moves) *out_heap_moves = heap_moves;
    if (out_generated_nodes) *out_generated_nodes = generated_nodes;
    if (out_valid_expansions) *out_valid_expansions = valid_expansions;

    if (plen == 0) {
        for (int t = 0; t <= T; t++) out_plan[t] = start;
        return 1;
    }
    for (int t = 0; t < plen; t++) {
        int idx = path_idx[plen - 1 - t];
        int tt = idx / (W * H);
        int rem = idx % (W * H);
        int y = rem / W, x = rem % W;
        if (tt <= T) out_plan[tt] = &map->grid[y][x];
    }
    {
        Node* last = out_plan[plen - 1 <= T ? plen - 1 : T];
        for (int t = plen; t <= T; t++) out_plan[t] = last;
    }

    return 1;
}

// ---- Partial-team CBS high-level ----
typedef struct {
    int a, b;
    int t;
    int is_edge;
    int ax, ay, bx, by;
    int apx, apy, bpx, bpy;
} CBSConflict;

static double cbs_cost_sum_adv(int ids[], int n,
    Node* plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1],
    Node* goals[MAX_AGENTS], int horizon) {
    const double ALPHA = 1.0, BETA = 0.5, GAMMA = 0.1;
    double s = 0.0;
    for (int i = 0; i < n; i++) {
        int id = ids[i];
        int moves = 0, waits = 0;
        for (int t = 1; t <= horizon; t++) {
            if (plans[id][t] != plans[id][t - 1]) moves++;
            else waits++;
        }
        {
            double hres = 0.0;
            if (goals[id]) {
                Node* last = plans[id][horizon];
                hres = manhattan_nodes(last, goals[id]);
            }
            s += ALPHA * moves + BETA * waits + GAMMA * hres;
        }
    }
    return s;
}
static int detect_first_conflict(Node* plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1], int ids[], int n, CBSConflict* out, int horizon) {
    for (int t = 1; t <= horizon; t++) {
        for (int i = 0; i < n; i++) for (int j = i + 1; j < n; j++) {
            int a = ids[i], b = ids[j];
            Node* a_t = plans[a][t];
            Node* b_t = plans[b][t];
            Node* a_tm1 = plans[a][t - 1];
            Node* b_tm1 = plans[b][t - 1];
            if (a_t == b_t) {
                out->a = a; out->b = b; out->t = t; out->is_edge = 0;
                out->ax = a_t->x; out->ay = a_t->y; out->bx = b_t->x; out->by = b_t->y;
                out->apx = a_tm1->x; out->apy = a_tm1->y; out->bpx = b_tm1->x; out->bpy = b_tm1->y;
                return 1;
            }
            if (a_t == b_tm1 && b_t == a_tm1) {
                out->a = a; out->b = b; out->t = t; out->is_edge = 1;
                out->ax = a_tm1->x; out->ay = a_tm1->y; out->bx = b_tm1->x; out->by = b_tm1->y;
                out->apx = a_tm1->x; out->apy = a_tm1->y; out->bpx = b_tm1->x; out->bpy = b_tm1->y;
                return 1;
            }
        }
    }
    return 0;
}
static void copy_ext_occ_without_group(const ReservationTable* base, int group_mask,
    int out_occ[MAX_WHCA_HORIZON + 1][GRID_HEIGHT][GRID_WIDTH]) {
    for (int t = 0; t <= g_whca_horizon; t++)
        for (int y = 0; y < GRID_HEIGHT; y++)
            for (int x = 0; x < GRID_WIDTH; x++) {
                int who = base->occ[t][y][x];
                if (who != -1 && (group_mask & (1 << who))) out_occ[t][y][x] = -1;
                else out_occ[t][y][x] = who;
            }
}

// --- CBS용 최소 힙---
static void cbs_heap_push(CBSNode* heap, int* hsize, const CBSNode* node) {
    /**
     * @brief CBS 노드 최소 힙에 노드를 삽입합니다.
     * @param heap 힙 배열
     * @param hsize 힙 크기(삽입 후 증가)
     * @param node 삽입할 노드
     */
    if (*hsize >= MAX_CBS_NODES) return;
    heap[*hsize] = *node;
    int i = *hsize;
    (*hsize)++;
    while (i > 0) {
        int p = (i - 1) / 2;
        if (heap[p].cost <= heap[i].cost) break;
        CBSNode tmp = heap[p]; heap[p] = heap[i]; heap[i] = tmp;
        i = p;
    }
}
static CBSNode cbs_heap_pop(CBSNode* heap, int* hsize) {
    /**
     * @brief CBS 노드 최소 힙에서 루트를 제거하여 반환합니다.
     * @param heap 힙 배열
     * @param hsize 힙 크기(감소)
     * @return 팝된 CBSNode
     */
    CBSNode ret = heap[0];
    *hsize = *hsize - 1;
    heap[0] = heap[*hsize];
    int i = 0;
    while (1) {
        int l = 2 * i + 1, r = 2 * i + 2, s = i;
        if (l < *hsize && heap[l].cost < heap[s].cost) s = l;
        if (r < *hsize && heap[r].cost < heap[s].cost) s = r;
        if (s == i) break;
        CBSNode tmp = heap[s]; heap[s] = heap[i]; heap[i] = tmp;
        i = s;
    }
    return ret;
}

// Partial CBS
static int run_partial_CBS(AgentManager* m, GridMap* map, Logger* lg,
    int group_ids[], int group_n, const ReservationTable* base_rt,
    Node* out_plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1]) {
    /**
     * @brief WFG로 감지된 소그룹에 대해 Partial CBS를 수행합니다.
     * @param m 에이전트 매니저
     * @param map 그리드 맵
     * @param lg 로거
     * @param group_ids 그룹 에이전트 ID 배열
     * @param group_n 그룹 크기
     * @param base_rt 기반 예약 테이블
     * @param out_plans 출력 계획(t=0..H)
     * @return 성공:1, 실패:0
     */
    if (group_n <= 1) return 0;

    int group_mask = 0; for (int i = 0; i < group_n; i++) group_mask |= (1 << group_ids[i]);

    // Move large temporaries out of the stack to avoid stack overflow (0xC00000FD)
    static int ext_occ[MAX_WHCA_HORIZON + 1][GRID_HEIGHT][GRID_WIDTH];
    copy_ext_occ_without_group(base_rt, group_mask, ext_occ);

    static CBSNode heap[MAX_CBS_NODES]; int hsize = 0; int expansions = 0;

    CBSNode root; memset(&root, 0, sizeof(root));
    for (int i = 0; i < group_n; i++) {
        int id = group_ids[i];
        Node* plan[MAX_WHCA_HORIZON + 1];
        unsigned long long nodes_exp = 0;
        unsigned long long heap_moves = 0;
        unsigned long long generated_nodes = 0;
        unsigned long long valid_expansions = 0;
        if (!st_astar_plan_single(id, map, m->agents[id].pos, m->agents[id].goal, g_whca_horizon, ext_occ,
            root.cons, root.ncons, plan, m->agents[id].heading, &nodes_exp, &heap_moves, &generated_nodes, &valid_expansions)) {
            g_metrics.cbs_ok_last = 0; g_metrics.cbs_exp_last = expansions; g_metrics.cbs_fail_sum++;
            return 0;
        }
        g_metrics.whca_nodes_expanded_this_step += nodes_exp;  // ��� Ȯ�� �� ����
        g_metrics.whca_heap_moves_this_step += heap_moves;
        g_metrics.whca_generated_nodes_this_step += generated_nodes;
        g_metrics.whca_valid_expansions_this_step += valid_expansions;
        for (int t = 0; t <= g_whca_horizon; t++) root.plans[id][t] = plan[t];
    }
    {
        Node* goals[MAX_AGENTS] = { 0 };
        for (int i = 0; i < group_n; i++) goals[group_ids[i]] = m->agents[group_ids[i]].goal;
        root.cost = cbs_cost_sum_adv(group_ids, group_n, root.plans, goals, g_whca_horizon);
    }
    cbs_heap_push(heap, &hsize, &root);

    while (hsize > 0 && expansions < CBS_MAX_EXPANSIONS) {
        CBSNode cur = cbs_heap_pop(heap, &hsize); expansions++;
        if (expansions > CBS_MAX_EXPANSIONS) break; // safety guard

        CBSConflict conf;
        if (!detect_first_conflict(cur.plans, group_ids, group_n, &conf, g_whca_horizon)) {
            for (int i = 0; i < group_n; i++) {
                int id = group_ids[i];
                for (int t = 0; t <= g_whca_horizon; t++) out_plans[id][t] = cur.plans[id][t];
            }
            logger_log(lg, "[%sCBS%s] 부분 팀 CBS 성공 (group=%d agents, expansions=%d).", C_B_GRN, C_NRM, group_n, expansions);
            g_metrics.cbs_ok_last = 1; g_metrics.cbs_exp_last = expansions; g_metrics.cbs_success_sum++;
            return 1;
        }

        for (int branch = 0; branch < 2; branch++) {
            if (hsize >= MAX_CBS_NODES) break;
            CBSNode child = cur; // copy by value (heap local); keep heap size bounded
            if (child.ncons >= MAX_CBS_CONS) continue;

            CBSConstraint c; memset(&c, 0, sizeof(c));
            if (branch == 0) c.agent = conf.a; else c.agent = conf.b;
            if (conf.is_edge) {
                c.is_edge = 1; c.t = conf.t - 1;
                if (branch == 0) { c.x = conf.apx; c.y = conf.apy; c.tox = conf.bpx; c.toy = conf.bpy; }
                else { c.x = conf.bpx; c.y = conf.bpy; c.tox = conf.apx; c.toy = conf.apy; }
            }
            else {
                c.is_edge = 0; c.t = conf.t;
                c.x = conf.ax; c.y = conf.ay;
            }
            child.cons[child.ncons++] = c;

            {
                int ok = 1;
                for (int i = 0; i < group_n; i++) {
                    int id = group_ids[i];
                    Node* plan[MAX_WHCA_HORIZON + 1];
                    unsigned long long nodes_exp = 0;
                    unsigned long long heap_moves = 0;
                    unsigned long long generated_nodes = 0;
                    unsigned long long valid_expansions = 0;
                    if (!st_astar_plan_single(id, map, m->agents[id].pos, m->agents[id].goal, g_whca_horizon, ext_occ,
                        child.cons, child.ncons, plan, m->agents[id].heading, &nodes_exp, &heap_moves, &generated_nodes, &valid_expansions)) {
                        ok = 0; break;
                    }
                    g_metrics.whca_nodes_expanded_this_step += nodes_exp;  // ��� Ȯ�� �� ����
                    g_metrics.whca_heap_moves_this_step += heap_moves;
                    g_metrics.whca_generated_nodes_this_step += generated_nodes;
                    g_metrics.whca_valid_expansions_this_step += valid_expansions;
                    for (int t = 0; t <= g_whca_horizon; t++) child.plans[id][t] = plan[t];
                }
                if (!ok) continue;
            }

            {
                Node* goals[MAX_AGENTS] = { 0 };
                for (int i = 0; i < group_n; i++) goals[group_ids[i]] = m->agents[group_ids[i]].goal;
                child.cost = cbs_cost_sum_adv(group_ids, group_n, child.plans, goals, g_whca_horizon);
            }

            cbs_heap_push(heap, &hsize, &child);
        }
    }
    logger_log(lg, "[%sCBS%s] 부분 팀 CBS 실패(시간/분기 한도). pull-over로 완화 시도.", C_B_RED, C_NRM);
    g_metrics.cbs_ok_last = 0; g_metrics.cbs_exp_last = expansions; g_metrics.cbs_fail_sum++;
    return 0;
}

void agent_manager_plan_and_resolve_collisions(AgentManager* m, GridMap* map, Logger* lg, Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief 통합 플래너: 목표 설정 → WHCA* 예약 → WFG/SCC → Partial CBS → pull-over로 충돌을 완화합니다.
     * @param m 에이전트 매니저
     * @param map 그리드 맵
     * @param lg 로거
     * @param next_pos 각 에이전트의 다음 위치 출력
     */
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &m->agents[i];
        g_agent_ops.setGoalIfNeeded(ag, map, m, lg);
    }
    for (int i = 0; i < MAX_AGENTS; i++) next_pos[i] = m->agents[i].pos;

    int order[MAX_AGENTS]; sort_agents_by_priority(m, order);

    ReservationTable rt; ReservationTable_clear(&rt); ReservationTable_seedCurrent(&rt, m);
    WaitEdge wf_edges[MAX_WAIT_EDGES]; int wf_cnt = 0;

    for (int oi = 0; oi < MAX_AGENTS; oi++) {
        int i = order[oi];
        Agent* ag = &m->agents[i];
        if (ag->state == IDLE || ag->state == CHARGING || ag->goal == NULL) continue;

        // 대기 타이머 중(목표 칸에서 작업 대기)인 경우: 호라이즌 전체 고정 예약 및 대기
        if (ag->action_timer > 0 && ag->pos && ag->goal && ag->pos == ag->goal) {
            for (int kk = 1; kk <= g_whca_horizon; kk++) {
                ReservationTable_setOccupant(&rt, kk, ag->pos, ag->id);
            }
            next_pos[ag->id] = ag->pos;
            continue;
        }

        ensure_pathfinder_for_agent(ag);

        {
            int goal_was_parked = (ag->state == GOING_TO_COLLECT && ag->goal->is_parked);
            if (goal_was_parked) ag->goal->is_parked = FALSE;

            if (ag->pf) {
                pathfinder_update_start(ag->pf, ag->pos);
                pathfinder_compute_shortest_path(ag->pf, map, m);
                // 메트릭 수집 (WHCA*의 D* Lite 부분을 전역 변수에 누적)
                g_metrics.whca_dstar_nodes_expanded_this_step += ag->pf->nodes_expanded_this_call;
                g_metrics.whca_dstar_heap_moves_this_step += ag->pf->heap_moves_this_call;
                g_metrics.whca_dstar_generated_nodes_this_step += ag->pf->nodes_generated_this_call;
                g_metrics.whca_dstar_valid_expansions_this_step += ag->pf->valid_expansions_this_call;
            }

            Node* plan[MAX_WHCA_HORIZON + 1]; plan[0] = ag->pos;
            Node* cur = ag->pos;

            for (int k = 1; k <= g_whca_horizon; k++) {
                Node* cand[5]; int cn = 0;
                best_candidate_order(ag->pf, map, m, cur, ag->pf->goal_node, cand, &cn);

                Node* chosen = cur;

                for (int ci = 0; ci < cn; ci++) {
                    Node* nb = cand[ci];

                    // 예약 충돌: 대기 에지 기록
                    if (ReservationTable_isOccupied(&rt, k, nb)) {
                        int who = ReservationTable_getOccupant(&rt, k, nb);
                        if (who != -1) add_wait_edge(wf_edges, &wf_cnt, ag->id, who, k, CAUSE_VERTEX, nb->x, nb->y, 0, 0);
                        continue;
                    }
                    // 스왑 충돌: 에지 기록
                    {
                        int who_prev = ReservationTable_getOccupant(&rt, k - 1, nb);
                        int who_into_cur = ReservationTable_getOccupant(&rt, k, cur);
                        if (who_prev != -1 && who_prev == who_into_cur) {
                            add_wait_edge(wf_edges, &wf_cnt, ag->id, who_prev, k, CAUSE_SWAP, cur->x, cur->y, nb->x, nb->y);
                            continue;
                        }
                    }

                    // 첫 번째 가용 후보를 선택하되, 끝까지 스캔하여 에지 수집은 지속
                    if (chosen == cur) {
                        chosen = nb;
                    }
                }

                plan[k] = chosen;
                ReservationTable_setOccupant(&rt, k, chosen, ag->id);
                cur = chosen;

                if (cur == ag->goal) {
                    for (int kk = k + 1; kk <= g_whca_horizon; kk++) ReservationTable_setOccupant(&rt, kk, cur, ag->id), plan[kk] = cur;
                    break;
                }
            }
            next_pos[ag->id] = plan[1];

            if (goal_was_parked) ag->goal->is_parked = TRUE;
        }
    }

    {
        // next_pos 기반 즉시 충돌을 WFG에 반영하여 SCC 검출 강화 (t=1)
        for (int i = 0; i < MAX_AGENTS; i++) {
            if (m->agents[i].state == IDLE || m->agents[i].state == CHARGING || m->agents[i].goal == NULL) continue;
            for (int j = i + 1; j < MAX_AGENTS; j++) {
                if (m->agents[j].state == IDLE || m->agents[j].state == CHARGING || m->agents[j].goal == NULL) continue;
                if (!next_pos[i] || !next_pos[j]) continue;
                // 동일 셀로 이동 의도: 양방향 wait 에지 추가
                if (next_pos[i] == next_pos[j]) {
                    add_wait_edge(wf_edges, &wf_cnt, i, j, 1, CAUSE_VERTEX, next_pos[i]->x, next_pos[i]->y, 0, 0);
                    add_wait_edge(wf_edges, &wf_cnt, j, i, 1, CAUSE_VERTEX, next_pos[j]->x, next_pos[j]->y, 0, 0);
                }
                // 스왑 의도: 양방향 swap 에지 추가
                else if (next_pos[i] == m->agents[j].pos && next_pos[j] == m->agents[i].pos) {
                    add_wait_edge(wf_edges, &wf_cnt, i, j, 1, CAUSE_SWAP,
                        m->agents[i].pos ? m->agents[i].pos->x : -1,
                        m->agents[i].pos ? m->agents[i].pos->y : -1,
                        next_pos[i]->x, next_pos[i]->y);
                    add_wait_edge(wf_edges, &wf_cnt, j, i, 1, CAUSE_SWAP,
                        m->agents[j].pos ? m->agents[j].pos->x : -1,
                        m->agents[j].pos ? m->agents[j].pos->y : -1,
                        next_pos[j]->x, next_pos[j]->y);
                }
            }
        }

        int sccMask = build_scc_mask_from_edges(wf_edges, wf_cnt);
        g_metrics.wf_edges_last = wf_cnt; g_metrics.wf_edges_sum += wf_cnt;
        g_metrics.scc_last = (sccMask ? 1 : 0); g_metrics.scc_sum += (sccMask ? 1 : 0);

        if (sccMask) {
            int group_ids[MAX_CBS_GROUP]; int group_n = 0;
            for (int i = 0; i < MAX_AGENTS && group_n < MAX_CBS_GROUP; i++) {
                if ((sccMask & (1 << i)) == 0) continue;
                if (m->agents[i].state == IDLE || m->agents[i].state == CHARGING || m->agents[i].goal == NULL) continue;
                if (m->agents[i].action_timer > 0 && m->agents[i].pos && m->agents[i].goal && m->agents[i].pos == m->agents[i].goal) continue; // 작업 대기 중인 에이전트 제외
                group_ids[group_n++] = i;
            }
            if (group_n >= 2) {
                Node* cbs_plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1] = { {0} };
                int ok = run_partial_CBS(m, map, lg, group_ids, group_n, &rt, cbs_plans);
                if (ok) {
                    for (int gi = 0; gi < group_n; gi++) {
                        int id = group_ids[gi];
                        if (cbs_plans[id][1]) next_pos[id] = cbs_plans[id][1];
                    }
                }
                else {
                    int leader = best_in_mask(m, sccMask);
                    for (int gi = 0; gi < group_n; gi++) {
                        int id = group_ids[gi];
                        if (id == leader) continue;
                        Node* po = try_pull_over(map, &rt, &m->agents[id]);
                        if (po) next_pos[id] = po;
                    }
                    logger_log(lg, "[%sWFG%s] SCC 감지: Leader=%c commit, others pull-over.", C_B_YEL, C_NRM, m->agents[leader].symbol);
                }
            }
        }
        else {
            // 폴백: SCC가 없지만 교착(모두 대기) 시 CBS를 2~3명 소그룹에 적용
            int active_ids[MAX_AGENTS]; int active_n = 0;
            for (int i = 0; i < MAX_AGENTS; i++) {
                Agent* ag = &m->agents[i];
                if (ag->state == IDLE || ag->state == CHARGING || ag->goal == NULL) continue;
                active_ids[active_n++] = i;
            }
            int all_wait = 1;
            for (int ai = 0; ai < active_n; ai++) {
                int id = active_ids[ai];
                if (next_pos[id] != m->agents[id].pos) { all_wait = 0; break; }
            }
            if (all_wait && active_n >= 2) {
                int order[MAX_AGENTS]; sort_agents_by_priority(m, order);
                int group_ids[MAX_CBS_GROUP]; int group_n = 0;
                for (int oi = 0; oi < MAX_AGENTS && group_n < MAX_CBS_GROUP; oi++) {
                    int id = order[oi];
                    Agent* ag = &m->agents[id];
                    if (ag->state == IDLE || ag->state == CHARGING || ag->goal == NULL) continue;
                    if (ag->action_timer > 0 && ag->pos && ag->goal && ag->pos == ag->goal) continue; // 작업 대기 중인 에이전트 제외
                    group_ids[group_n++] = id;
                }
                if (group_n >= 2) {
                    Node* cbs_plans[MAX_AGENTS][MAX_WHCA_HORIZON + 1] = { {0} };
                    int ok = run_partial_CBS(m, map, lg, group_ids, group_n, &rt, cbs_plans);
                    if (ok) {
                        for (int gi = 0; gi < group_n; gi++) {
                            int id = group_ids[gi];
                            if (cbs_plans[id][1]) next_pos[id] = cbs_plans[id][1];
                        }
                        logger_log(lg, "[%sCBS%s] Deadlock fallback CBS 적용 (group=%d).", C_B_CYN, C_NRM, group_n);
                    }
                    else {
                        // 마지막 폴백: 리더 1대만 진행, 나머지 전원 pull-over
                        int leader = best_in_mask(m, sccMask ? sccMask : 0x3FF);
                        for (int gi = 0; gi < group_n; gi++) {
                            int id = group_ids[gi];
                            if (id == leader) continue;
                            Node* po = try_pull_over(map, &rt, &m->agents[id]);
                            if (po) next_pos[id] = po;
                        }
                        logger_log(lg, "[%sWFG%s] Deadlock fallback: leader-only move, others pull-over.", C_B_YEL, C_NRM);
                    }
                }
            }
        }
    }

    for (int i = 0; i < MAX_AGENTS; i++) {
        for (int j = i + 1; j < MAX_AGENTS; j++) {
            if (m->agents[i].state == IDLE || m->agents[j].state == IDLE ||
                m->agents[i].state == CHARGING || m->agents[j].state == CHARGING) continue;

            if (next_pos[i] == next_pos[j]) {
                // 주차 진행 차량은 빈차 복귀 차량보다 항시 우선
                if ((m->agents[i].state == GOING_TO_PARK && m->agents[j].state == RETURNING_HOME_EMPTY) ||
                    (m->agents[j].state == GOING_TO_PARK && m->agents[i].state == RETURNING_HOME_EMPTY)) {
                    if (m->agents[i].state == RETURNING_HOME_EMPTY) {
                        logger_log(lg, "[%sAvoid%s] 정점 충돌(주차>빈차): Agent %c 대기.", C_B_RED, C_NRM, m->agents[i].symbol);
                        next_pos[i] = m->agents[i].pos;
                    }
                    else {
                        logger_log(lg, "[%sAvoid%s] 정점 충돌(주차>빈차): Agent %c 대기.", C_B_RED, C_NRM, m->agents[j].symbol);
                        next_pos[j] = m->agents[j].pos;
                    }
                }
                else {
                    int pi = priority_score(&m->agents[i]);
                    int pj = priority_score(&m->agents[j]);
                    if (pi >= pj) { logger_log(lg, "[%sAvoid%s] 정점 충돌 → Agent %c 대기.", C_B_RED, C_NRM, m->agents[j].symbol); next_pos[j] = m->agents[j].pos; }
                    else { logger_log(lg, "[%sAvoid%s] 정점 충돌 → Agent %c 대기.", C_B_RED, C_NRM, m->agents[i].symbol); next_pos[i] = m->agents[i].pos; }
                }
            }
            else if (next_pos[i] == m->agents[j].pos && next_pos[j] == m->agents[i].pos) {
                // 주차 진행 차량은 빈차 복귀 차량보다 항시 우선
                if ((m->agents[i].state == GOING_TO_PARK && m->agents[j].state == RETURNING_HOME_EMPTY) ||
                    (m->agents[j].state == GOING_TO_PARK && m->agents[i].state == RETURNING_HOME_EMPTY)) {
                    if (m->agents[i].state == RETURNING_HOME_EMPTY) {
                        logger_log(lg, "[%sAvoid%s] 스왑 충돌(주차>빈차): Agent %c 대기.", C_B_RED, C_NRM, m->agents[i].symbol);
                        next_pos[i] = m->agents[i].pos;
                    }
                    else {
                        logger_log(lg, "[%sAvoid%s] 스왑 충돌(주차>빈차): Agent %c 대기.", C_B_RED, C_NRM, m->agents[j].symbol);
                        next_pos[j] = m->agents[j].pos;
                    }
                }
                else {
                    int pi = priority_score(&m->agents[i]);
                    int pj = priority_score(&m->agents[j]);
                    if (pi >= pj) { logger_log(lg, "[%sAvoid%s] 스왑 충돌 → Agent %c 대기.", C_B_RED, C_NRM, m->agents[j].symbol); next_pos[j] = m->agents[j].pos; }
                    else { logger_log(lg, "[%sAvoid%s] 스왑 충돌 → Agent %c 대기.", C_B_RED, C_NRM, m->agents[i].symbol); next_pos[i] = m->agents[i].pos; }
                }
            }
        }
    }

    // 호라이즌 자동 조정
    WHCA_adjustHorizon(wf_cnt, g_metrics.scc_last, lg);
}

// 모든 Pathfinder에 환경 변화 통지
static void broadcast_cell_change(AgentManager* am, GridMap* map, Node* changed) {
    /**
     * @brief 모든 Pathfinder에 특정 셀의 환경 변화를 통지합니다.
     * @param am 에이전트 매니저
     * @param map 그리드 맵
     * @param changed 변경된 노드
     */
    if (!map || !changed) return;
    for (int a = 0; a < MAX_AGENTS; a++) {
        if (am->agents[a].pf) pathfinder_notify_cell_change(am->agents[a].pf, map, am, changed);
    }
}

void agent_manager_update_state_after_move(AgentManager* m, ScenarioManager* sc, GridMap* map, Logger* lg, Simulation* sim) {
    /**
     * @brief 이동 적용 후 목표 도달/작업 대기/상태 전이를 처리하고 메트릭/예약을 갱신합니다.
     * @param m 에이전트 매니저
     * @param sc 시나리오 매니저
     * @param map 그리드 맵
     * @param lg 로거
     * @param sim 시뮬레이션(집계 메트릭 반영)
     */
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &m->agents[i];
        if (ag->state == IDLE || ag->state == CHARGING || !ag->goal || ag->pos != ag->goal) continue;

        // 주차/출차 도착 시 대기 로직
        if (ag->state == GOING_TO_PARK || ag->state == GOING_TO_COLLECT) {
            if (ag->action_timer <= 0) {
                ag->action_timer = TASK_ACTION_TICKS;
                logger_log(lg, "[%sTask%s] Agent %c, %s 작업 대기 %dtick.", C_YEL, C_NRM, ag->symbol,
                    ag->state == GOING_TO_PARK ? "주차" : "출차", ag->action_timer);
                continue; // 대기 시작: 즉시 완료 처리하지 않음
            }
            else {
                ag->action_timer--;
                if (ag->action_timer > 0) {
                    continue; // 대기 진행 중
                }
                // action_timer가 0이 되었으므로 아래에서 완료 처리로 진행
            }
        }

        Node* reached = ag->goal;
        if (ag->state != GOING_TO_CHARGE) reached->reserved_by_agent = -1;
        ag->goal = NULL;

        switch (ag->state) {
        case GOING_TO_PARK:
            reached->is_parked = TRUE; m->total_cars_parked++;
            broadcast_cell_change(m, map, reached);
            logger_log(lg, "[%sPark%s] Agent %c, 주차 완료 at (%d,%d).", C_GRN, C_NRM, ag->symbol, reached->x, reached->y);
            if (sc->mode == MODE_CUSTOM && sc->current_phase_index < sc->num_phases &&
                sc->phases[sc->current_phase_index].type == PARK_PHASE) {
                sc->tasks_completed_in_phase++;
                if (sim) {
                    int phase_idx = sc->current_phase_index;
                    if (phase_idx >= 0 && phase_idx < MAX_PHASES) {
                        sim->phase_completed_tasks[phase_idx]++;
                    }
                    sim->tasks_completed_total++;
                }
            }
            else if (sim) {
                sim->tasks_completed_total++;
            }
            ag->state = RETURNING_HOME_EMPTY;
            if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
            break;
        case RETURNING_HOME_EMPTY:
            logger_log(lg, "[%sInfo%s] Agent %c, 주차 작업 후 기지 복귀 완료.", C_CYN, C_NRM, ag->symbol);
            ag->state = IDLE;
            if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
            // --- metrics aggregate for PARK cycle ---
            metrics_finalize_task_if_active(sim, ag);
            break;
        case GOING_TO_COLLECT:
            logger_log(lg, "[%sExit%s] Agent %c, 차량 수거 at (%d,%d).", C_YEL, C_NRM, ag->symbol, reached->x, reached->y);
            reached->is_parked = FALSE; m->total_cars_parked--;
            broadcast_cell_change(m, map, reached);
            ag->state = RETURNING_WITH_CAR;
            if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
            break;
        case RETURNING_WITH_CAR:
            logger_log(lg, "[%sExit%s] Agent %c, 차량 출차 완료.", C_GRN, C_NRM, ag->symbol);
            if (sc->mode == MODE_CUSTOM && sc->current_phase_index < sc->num_phases &&
                sc->phases[sc->current_phase_index].type == EXIT_PHASE) {
                sc->tasks_completed_in_phase++;
                if (sim) {
                    int phase_idx = sc->current_phase_index;
                    if (phase_idx >= 0 && phase_idx < MAX_PHASES) {
                        sim->phase_completed_tasks[phase_idx]++;
                    }
                    sim->tasks_completed_total++;
                }
            }
            else if (sim) {
                sim->tasks_completed_total++;
            }
            ag->state = IDLE;
            if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
            // --- metrics aggregate for EXIT cycle ---
            metrics_finalize_task_if_active(sim, ag);
            break;
        case GOING_TO_CHARGE:
            logger_log(lg, "[%sCharge%s] Agent %c, 충전 시작. (%d steps)", C_B_YEL, C_NRM, ag->symbol, CHARGE_TIME);
            ag->state = CHARGING; ag->charge_timer = CHARGE_TIME;
            if (ag->pos) broadcast_cell_change(m, map, ag->pos);
            break;
        case RETURNING_HOME_MAINTENANCE:
            logger_log(lg, "[%sInfo%s] Agent %c, 충전 후 기지 복귀 완료.", C_CYN, C_NRM, ag->symbol);
            ag->state = IDLE;
            if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
            break;
        default: break;
        }
        ag->stuck_steps = 0;
    }
}
void agent_manager_update_charge_state(AgentManager* m, GridMap* map, Logger* lg) {
    /**
     * @brief 충전 상태 에이전트의 타이머를 감소시키고 완료 시 상태를 전환합니다.
     * @param m 에이전트 매니저
     * @param map 그리드 맵
     * @param lg 로거
     */
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &m->agents[i];
        if (ag->state == CHARGING) {
            ag->charge_timer--;
            if (ag->charge_timer <= 0) {
                logger_log(lg, "[%sCharge%s] Agent %c 충전 완료.", C_B_GRN, C_NRM, ag->symbol);
                ag->total_distance_traveled = 0.0;
                ag->state = RETURNING_HOME_MAINTENANCE;
                if (ag->pos) ag->pos->reserved_by_agent = -1;
                if (ag->pos) broadcast_cell_change(m, map, ag->pos);
                ag->goal = NULL;
                if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
                ag->stuck_steps = 0;
            }
        }
    }
}

// --- WHCA* 호라이즌 자동 조정 ---
// 충돌 점수에 따라 호라이즌을 동적으로 조정
static void WHCA_adjustHorizon(int wf_edges, int scc, Logger* lg) {
    /**
     * @brief 최근 충돌 지표를 기반으로 WHCA* 호라이즌을 동적으로 조정합니다.
     * @param wf_edges 수집된 대기 에지 수
     * @param scc SCC 감지 여부(0/1)
     * @param lg 로거
     */
    g_conflict_score = (int)(g_conflict_score * 0.6) + wf_edges + (scc ? 5 : 0);
    {
        int oldH = g_whca_horizon;
        const int HI = 24;
        const int LO = 10;

        if (g_conflict_score > HI && g_whca_horizon < MAX_WHCA_HORIZON) g_whca_horizon += 2;
        else if (g_conflict_score < LO && g_whca_horizon > MIN_WHCA_HORIZON) g_whca_horizon -= 2;

        if (g_whca_horizon < MIN_WHCA_HORIZON) g_whca_horizon = MIN_WHCA_HORIZON;
        if (g_whca_horizon > MAX_WHCA_HORIZON) g_whca_horizon = MAX_WHCA_HORIZON;

        if (oldH != g_whca_horizon) {
            logger_log(lg, "[%sWHCA*%s] Horizon 변경: %d → %d (score=%d)", C_B_CYN, C_NRM, oldH, g_whca_horizon, g_conflict_score);
        }
        g_metrics.whca_h = g_whca_horizon;
    }
}

// =============================================================================
// 섹션 9-대체: 대체 플래너 ( A* / D* Lite)
// =============================================================================

// A* 기반 계획 및 충돌 해결 (단순 한 스텝 계획)
void agent_manager_plan_and_resolve_collisions_astar(AgentManager* manager, GridMap* map, Logger* logger, Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief A* 기반 한 스텝 계획 + 우선순위 충돌 해소를 수행합니다.
     * @param manager 에이전트 매니저
     * @param map 그리드 맵
     * @param logger 로거
     * @param next_pos 다음 위치 출력
     */
     // 1. 목표 설정 및 next_pos 초기화 (모든 에이전트는 현재 위치에서 대기)
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* agent = &manager->agents[i];
        g_agent_ops.setGoalIfNeeded(agent, map, manager, logger);
        next_pos[i] = agent->pos;
    }

    // 2. 우선순위 기반 순차 계획 (회전 로직 통합)
    int order[MAX_AGENTS];
    sort_agents_by_priority(manager, order);
    for (int oi = 0; oi < MAX_AGENTS; oi++) {
        int i = order[oi];
        Agent* agent = &manager->agents[i];
        Node* current_pos = agent->pos;

        // 이미 회전 또는 작업 대기 중인 경우, 계획 없이 대기 확정
        if (agent->rotation_wait > 0) {
            agent->rotation_wait--;
            continue; // next_pos[i]는 이미 current_pos로 설정됨
        }
        if (agent->action_timer > 0) {
            continue; // 작업 타이머가 있는 에이전트는 움직이지 않음
        }

        // 계획이 필요 없는 상태면 건너뜀
        if (agent->state == IDLE || agent->state == CHARGING || agent->goal == NULL || !current_pos) {
            continue;
        }

        // 3. A*로 이상적인 다음 스텝(desired_move) 계획 (우선순위 높은 에이전트의 next_pos, 낮은 에이전트의 현재 pos를 임시 장애물로 사용)
        Node* desired_move = current_pos;
        {
            TempMarkContext ctx; temp_context_init(&ctx, NULL, map, manager, 0);
            for (int h = 0; h < oi; h++) {
                int hid = order[h];
                if (next_pos[hid]) temp_context_mark(&ctx, next_pos[hid]);
            }
            for (int l = oi + 1; l < MAX_AGENTS; l++) {
                int lid = order[l];
                if (manager->agents[lid].pos) temp_context_mark(&ctx, manager->agents[lid].pos);
            }

            int goal_was_parked = (agent->state == GOING_TO_COLLECT && agent->goal->is_parked);
            if (goal_was_parked) agent->goal->is_parked = FALSE;

            Pathfinder* pf = g_pf_factory.create(agent->pos, agent->goal);
            pathfinder_compute_shortest_path(pf, map, manager);

            // 메트릭 수집 (pf가 destroy되기 전에 직접 전역 변수에 누적)
            g_metrics.astar_nodes_expanded_this_step += pf->nodes_expanded_this_call;
            g_metrics.astar_heap_moves_this_step += pf->heap_moves_this_call;
            g_metrics.astar_generated_nodes_this_step += pf->nodes_generated_this_call;
            g_metrics.astar_valid_expansions_this_step += pf->valid_expansions_this_call;

            desired_move = pathfinder_get_next_step(pf, map, manager, agent->pos);
            g_pf_factory.destroy(pf);

            if (goal_was_parked) agent->goal->is_parked = TRUE;
            temp_context_cleanup(&ctx);
        }

        // 4. 회전 로직을 적용하여 실제 다음 스텝(next_pos[i]) 확정
        agent_apply_rotation_and_step(agent, current_pos, desired_move, &next_pos[i]);
    }

    // 5. 최종 충돌 방지 (공통 함수)
    resolve_conflicts_by_order(manager, order, next_pos);
}

void agent_manager_plan_and_resolve_collisions_dstar_basic(AgentManager* m, GridMap* map, Logger* lg, Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief 기본 D* Lite 기반 한 스텝 계획 + 우선순위 충돌 해소를 수행합니다.
     * @param m 에이전트 매니저
     * @param map 그리드 맵
     * @param lg 로거
     * @param next_pos 다음 위치 출력
     */
     // 1. 목표 설정 및 next_pos 초기화
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &m->agents[i];
        g_agent_ops.setGoalIfNeeded(ag, map, m, lg);
        next_pos[i] = ag->pos;
    }

    // 2. 우선순위 기반 순차 계획 (회전 로직 통합)
    int order[MAX_AGENTS];
    sort_agents_by_priority(m, order);
    for (int oi = 0; oi < MAX_AGENTS; oi++) {
        int i = order[oi];
        Agent* ag = &m->agents[i];
        Node* current_pos = ag->pos;

        // 이미 회전 또는 작업 대기 중인 경우, 계획 없이 대기 확정
        if (ag->rotation_wait > 0) {
            ag->rotation_wait--;
            continue;
        }
        if (ag->action_timer > 0) {
            continue;
        }

        // 계획이 필요 없는 상태면 건너뜀
        if (ag->state == IDLE || ag->state == CHARGING || ag->goal == NULL || !current_pos) {
            continue;
        }

        // 3. D* Lite로 이상적인 다음 스텝(desired_move) 계획 (우선순위 높은 에이전트의 next_pos, 낮은 에이전트의 현재 pos를 임시 장애물로 사용)
        Node* desired_move = current_pos;
        {
            if (!ag->pf) {
                ag->pf = pathfinder_create(ag->pos, ag->goal, ag);
            }
            else if (ag->pf->goal_node != ag->goal) {
                ag->pf->start_node = ag->pos;
                pathfinder_reset_goal(ag->pf, ag->goal);
            }

            TempMarkContext ctx; temp_context_init(&ctx, ag->pf, map, m, 1);
            for (int h = 0; h < oi; h++) {
                int hid = order[h];
                if (next_pos[hid]) temp_context_mark(&ctx, next_pos[hid]);
            }
            for (int l = oi + 1; l < MAX_AGENTS; l++) {
                int lid = order[l];
                if (m->agents[lid].pos) temp_context_mark(&ctx, m->agents[lid].pos);
            }

            int goal_was_parked = (ag->state == GOING_TO_COLLECT && ag->goal->is_parked);
            if (goal_was_parked) { ag->goal->is_parked = FALSE; if (ag->pf) pathfinder_notify_cell_change(ag->pf, map, m, ag->goal); }

            if (ag->pf) {
                pathfinder_update_start(ag->pf, ag->pos);
                pathfinder_compute_shortest_path(ag->pf, map, m);
                // 메트릭 수집 (D* Lite 알고리즘의 메트릭을 전역 변수에 누적)
                g_metrics.dstar_nodes_expanded_this_step += ag->pf->nodes_expanded_this_call;
                g_metrics.dstar_heap_moves_this_step += ag->pf->heap_moves_this_call;
                g_metrics.dstar_generated_nodes_this_step += ag->pf->nodes_generated_this_call;
                g_metrics.dstar_valid_expansions_this_step += ag->pf->valid_expansions_this_call;
                desired_move = pathfinder_get_next_step(ag->pf, map, m, ag->pos);
            }

            if (goal_was_parked) { ag->goal->is_parked = TRUE; if (ag->pf) pathfinder_notify_cell_change(ag->pf, map, m, ag->goal); }
            temp_context_cleanup(&ctx);
        }

        // 4. 회전 로직 적용하여 실제 다음 스텝 확정
        agent_apply_rotation_and_step(ag, current_pos, desired_move, &next_pos[i]);
    }

    // 5. 최종 충돌 방지 (공통 함수)
    resolve_conflicts_by_order(m, order, next_pos);
}
// =============================================================================
// 섹션 9-전략: 플래너 전략 구현 (전략 패턴)
// =============================================================================
static void planner_plan_default(AgentManager* am, GridMap* map, Logger* lg, Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief 통합 기본 플래너(WHCA*+D*Lite+WFG+CBS)를 호출합니다.
     */
    agent_manager_plan_and_resolve_collisions(am, map, lg, next_pos);
}
static void planner_plan_astar(AgentManager* am, GridMap* map, Logger* lg, Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief 단순 A* 플래너를 호출합니다.
     */
    agent_manager_plan_and_resolve_collisions_astar(am, map, lg, next_pos);
}
static void planner_plan_dstar(AgentManager* am, GridMap* map, Logger* lg, Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief 기본 D* Lite 플래너를 호출합니다.
     */
    agent_manager_plan_and_resolve_collisions_dstar_basic(am, map, lg, next_pos);
}

static Planner planner_make_default(void) {
    /**
     * @brief 기본 플래너 vtable을 생성합니다.
     */
    Planner p; p.vtbl.plan_step = planner_plan_default; return p;
}
static Planner planner_make_astar(void) {
    /**
     * @brief A* 플래너 vtable을 생성합니다.
     */
    Planner p; p.vtbl.plan_step = planner_plan_astar; return p;
}
static Planner planner_make_dstar(void) {
    /**
     * @brief D* Lite 플래너 vtable을 생성합니다.
     */
    Planner p; p.vtbl.plan_step = planner_plan_dstar; return p;
}

static Planner planner_from_pathalgo(PathAlgo algo) {
    /**
     * @brief 열거형 설정에 따라 적절한 플래너 vtable을 반환합니다.
     * @param algo 선택 알고리즘
     * @return Planner 구조체(vtable 포함)
     */
    switch (algo) {
    case PATHALGO_ASTAR_SIMPLE: return planner_make_astar();
    case PATHALGO_DSTAR_BASIC:  return planner_make_dstar();
    case PATHALGO_DEFAULT:
    default:                    return planner_make_default();
    }
}
// --- 공통 충돌 해결 (우선순위 배열에 따라 낮은 우선순위 에이전트가 대기) ---
// 우선순위 배열을 기준으로 충돌 시 후순위 에이전트를 대기시킴
static void resolve_conflicts_by_order(const AgentManager* m, const int order[MAX_AGENTS], Node* next_pos[MAX_AGENTS]) {
    /**
     * @brief 우선순위 배열에 따라 충돌 시 후순위 에이전트를 대기시킵니다.
     * @param m 에이전트 매니저
     * @param order 우선순위 높은 순의 인덱스 배열
     * @param next_pos 계획된 다음 위치 배열(수정됨)
     */
    for (int oi = 0; oi < MAX_AGENTS; oi++) {
        int i = order[oi];
        for (int oj = oi + 1; oj < MAX_AGENTS; oj++) {
            int j = order[oj];
            if (!next_pos[i] || !next_pos[j]) continue;
            if (next_pos[i] == next_pos[j] ||
                (next_pos[i] == m->agents[j].pos && next_pos[j] == m->agents[i].pos)) {
                next_pos[j] = ((AgentManager*)m)->agents[j].pos;
            }
            // 추가 규칙: 정지 중인 타 에이전트의 현재 칸으로의 진입 금지
            else if (next_pos[i] == m->agents[j].pos && next_pos[j] == m->agents[j].pos) {
                next_pos[i] = ((AgentManager*)m)->agents[i].pos;
            }
        }
    }
}
// =============================================================================
// 섹션 10: 시뮬레이션 핵심 (맵 선택 포함)
// =============================================================================
/**
 * @brief 지정한 밀리초(ms) 동안 대기합니다.
 * @param ms 대기 시간(ms)
 */
static void do_ms_pause(int ms) { sleep_ms(ms); }

/**
 * @brief 사용자 정의(Custom) 시나리오를 대화형으로 구성합니다.
 * @param sim 시뮬레이션 인스턴스
 * @return 성공:1, 취소:0
 */
static int simulation_setup_custom_scenario(Simulation* sim) {
    ScenarioManager* s = sim->scenario_manager;

    printf(C_B_WHT "--- 사용자 정의 시나리오 설정 ---\n" C_NRM);
    s->num_phases = get_integer_input(C_YEL "총 단계 수를 입력(1-20, 0=취소): " C_NRM, 0, MAX_PHASES);
    if (s->num_phases == 0) return 0;

    int max_per_phase = (sim->map && sim->map->num_goals > 0) ? sim->map->num_goals : 100000;

    for (int i = 0; i < s->num_phases; i++) {
        printf(C_B_CYN "\n--- %d/%d 단계 설정 ---\n" C_NRM, i + 1, s->num_phases);
        printf("a. %s주차%s\n", C_YEL, C_NRM);
        printf("b. %s출차%s\n", C_CYN, C_NRM);
        char c = get_char_input("단계 유형 선택: ", "ab");

        char prompt[64];
        snprintf(prompt, sizeof(prompt), "이 단계 차량 수 (1~%d): ", max_per_phase);
        s->phases[i].task_count = get_integer_input(prompt, 1, max_per_phase);

        if (c == 'a') { s->phases[i].type = PARK_PHASE;  snprintf(s->phases[i].type_name, sizeof(s->phases[i].type_name), "주차"); }
        else { s->phases[i].type = EXIT_PHASE;  snprintf(s->phases[i].type_name, sizeof(s->phases[i].type_name), "출차"); }

        printf(C_GRN "%d단계 설정 완료: %s %d대.\n" C_NRM, i + 1, s->phases[i].type_name, s->phases[i].task_count);
    }
    printf(C_B_GRN "\n--- 시나리오 설정 완료 ---\n" C_NRM);
    do_ms_pause(1500);
    return 1;
}

/**
 * @brief 실시간 모드의 요청 확률(주차/출차)을 설정합니다.
 * @param s 시나리오 매니저
 * @return 성공:1
 */
static int simulation_setup_realtime(ScenarioManager* s) {
    printf(C_B_WHT "--- 실시간 시뮬레이션 설정 ---\n" C_NRM);
    while (TRUE) {
        s->park_chance = get_integer_input("\n주차 요청 확률(0~100): ", 0, 100);
        s->exit_chance = get_integer_input("출차 요청 확률(0~100): ", 0, 100);
        if (s->park_chance + s->exit_chance <= 100) break;
        printf(C_B_RED "합은 100을 넘을 수 없습니다.\n" C_NRM);
    }
    printf(C_B_GRN "\n설정 완료: 주차 %d%%, 출차 %d%%\n" C_NRM, s->park_chance, s->exit_chance);
    do_ms_pause(1500); return 1;
}
/**
 * @brief 시뮬레이션 속도(배속)를 설정하고 sleep 간격을 계산합니다.
 * @param s 시나리오 매니저
 * @return 성공:1
 */
static int simulation_setup_speed(ScenarioManager* s) {
    printf(C_B_WHT "\n--- 시뮬레이션 속도 설정 ---\n" C_NRM);

    // 0.0 허용(= 무제한), 계산 결과 0ms 가능
    s->speed_multiplier = get_float_input("배속 (0.0=무제한 ~ 10000.0): ", 0.0f, MAX_SPEED_MULTIPLIER);
    if (s->speed_multiplier <= 0.0f) {
        s->simulation_speed = 0;          // 0ms sleep
    }
    else {
        s->simulation_speed = (int)(100.0f / s->speed_multiplier);
        if (s->simulation_speed < 0) s->simulation_speed = 0;
    }

    printf(C_B_GRN "\n--- %.1fx 배속으로 시작합니다... ---\n" C_NRM, s->speed_multiplier);
    do_ms_pause(1500);
    return 1;
}


// ★ Map 선택 단계
/**
 * @brief 실행 전 사용할 맵(1~5)을 선택하고 로드합니다.
 * @param sim 시뮬레이션 인스턴스
 * @return 성공:1
 */
static int simulation_setup_map(Simulation* sim) {
    printf(C_B_WHT "--- 맵 선택 (1~5) ---\n" C_NRM);
    printf("1. %s기본 주차장%s (기존)\n", C_B_GRN, C_NRM);
    printf("2. %s대형마트형 1차선 격자%s\n", C_B_YEL, C_NRM);
    printf("3. %s8 AGV + 900칸%s (스타트 16×6, A~H)\n", C_B_YEL, C_NRM);
    printf("4. %s격자도로(1차선) + 주차블록 4개%s (스타트 10×4, A~J)\n", C_B_YEL, C_NRM);
    printf("5. %s십자가 맵%s (중앙 충전소, 끝점 에이전트, +4칸에 주차)\n\n", C_B_YEL, C_NRM);
    int mid = get_integer_input("맵 번호를 선택하세요 (1~5): ", 1, 5);
    sim->map_id = mid;
    grid_map_load_scenario(sim->map, sim->agent_manager, mid);
    logger_log(sim->logger, "[%sMap%s] 맵 #%d 로드 완료.", C_B_CYN, C_NRM, mid);
    do_ms_pause(800);
    return 1;
}

/**
 * @brief 맵/알고리즘/실행 모드를 차례로 설정합니다.
 * @param sim 시뮬레이션 인스턴스
 * @return 성공:1, 취소:0
 */
int simulation_setup(Simulation* sim) {
    ui_clear_screen_optimized();
    // ★ 먼저 맵 선택
    if (!simulation_setup_map(sim)) return 0;

    // ★ 경로계획 알고리즘 선택
    printf(C_B_WHT "\n--- 경로계획 알고리즘 선택 ---\n" C_NRM);
    printf("1. %s기본(WHCA* + D* Lite + WFG + CBS)%s\n", C_B_GRN, C_NRM);
    printf("2. %sA* (코드2) - 단순 A* 기반 한 스텝 계획%s\n", C_B_YEL, C_NRM);
    printf("3. %sD* Lite (코드3) - 증분형 기본 예약형%s\n\n", C_B_YEL, C_NRM);
    {
        int a = get_integer_input("알고리즘 번호 (1~3): ", 1, 3);
        sim->path_algo = (a == 2) ? PATHALGO_ASTAR_SIMPLE : (a == 3) ? PATHALGO_DSTAR_BASIC : PATHALGO_DEFAULT;
        logger_log(sim->logger, "[%sAlgo%s] 선택: %d", C_B_CYN, C_NRM, a);
        // 알고리즘에 따라 기본 렌더 프레임 stride 자동 설정(초기 렉 완화)
        if (sim->path_algo == PATHALGO_DEFAULT) g_renderer.render_stride = 1;         // 통합 알고리즘: 기본 그대로
        else if (sim->path_algo == PATHALGO_DSTAR_BASIC) g_renderer.render_stride = 2; // 증분형: 약간만 스킵
        else g_renderer.render_stride = 2;                                            // A*: 비슷하게 2로
        // 전략 플래너 바인딩
        sim->planner = planner_from_pathalgo(sim->path_algo);
    }

    printf(C_B_WHT "\n--- 시뮬레이션 모드 선택 ---\n" C_NRM);
    printf("a. %s사용자 정의 시나리오%s\n", C_YEL, C_NRM);
    printf("b. %s실시간 시뮬레이션%s\n", C_CYN, C_NRM);
    printf("q. %s종료%s\n\n", C_RED, C_NRM);
    char c = get_char_input("실행할 모드: ", "abq");
    int ok = 0;
    switch (c) {
    case 'a': sim->scenario_manager->mode = MODE_CUSTOM;
        if (simulation_setup_custom_scenario(sim))
            ok = simulation_setup_speed(sim->scenario_manager);
        break;
    case 'b': sim->scenario_manager->mode = MODE_REALTIME;
        if (simulation_setup_realtime(sim->scenario_manager))
            ok = simulation_setup_speed(sim->scenario_manager);
        break;
    case 'q': return 0;
    }
    if (ok) ui_clear_screen_optimized();
    return ok;
}

/**
 * @brief 한 틱의 상태 갱신(충전, 작업 생성/할당, IDLE 에이전트 활성화)을 수행합니다.
 * @param sim 시뮬레이션 인스턴스
 */
static void simulation_update_state(Simulation* sim) {
    ScenarioManager* sc = sim->scenario_manager;
    AgentManager* am = sim->agent_manager;
    GridMap* map = sim->map;
    Logger* lg = sim->logger;

    if (sc->mode == MODE_CUSTOM) {
        if (sc->current_phase_index >= sc->num_phases) return;
        DynamicPhase* ph = &sc->phases[sc->current_phase_index];
        if (sc->tasks_completed_in_phase >= ph->task_count) {
            logger_log(lg, "[%sPhase%s] %d단계 (%s %d대) 완료!", C_B_YEL, C_NRM,
                sc->current_phase_index + 1, ph->type_name, ph->task_count);
            sc->current_phase_index++; sc->tasks_completed_in_phase = 0;
            if (sc->current_phase_index < sc->num_phases) {
                DynamicPhase* nx = &sc->phases[sc->current_phase_index];
                logger_log(lg, "[%sPhase%s] %d단계 시작: %s %d대.",
                    C_B_YEL, C_NRM, sc->current_phase_index + 1, nx->type_name, nx->task_count);
                do_ms_pause(1500);
            }
            return;
        }
    }
    else if (sc->mode == MODE_REALTIME) {
        if (sc->time_step > 0) {
            // 기대값 모델: 100% -> 틱당 0.2 확률 → 평균 5틱/건
            // 따라서 p%일 때 틱당 확률 = p/500
            int roll_park = rand() % 500;
            int roll_exit = rand() % 500;

            if (sc->park_chance > 0 && roll_park < sc->park_chance) {
                int before = sc->task_count;
                if (am->total_cars_parked < map->num_goals) {
                    logger_log(lg, "[%sEvent%s] 새로운 주차 요청.", C_B_GRN, C_NRM);
                    add_task_to_queue(sc, TASK_PARK);
                }
                if (sim && sc->task_count > before) sim->requests_created_total++;
            }

            if (sc->exit_chance > 0 && roll_exit < sc->exit_chance) {
                int before2 = sc->task_count;
                if (am->total_cars_parked > 0) {
                    logger_log(lg, "[%sEvent%s] 새로운 출차 요청.", C_B_YEL, C_NRM);
                    add_task_to_queue(sc, TASK_EXIT);
                }
                if (sim && sc->task_count > before2) sim->requests_created_total++;
            }
        }
    }

    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &am->agents[i];
        if (ag->state == IDLE) {
            if (!ag->pos) continue;
            if (ag->total_distance_traveled >= DISTANCE_BEFORE_CHARGE) {
                if (select_best_charge_station(ag, map, am, lg)) { ag->state = GOING_TO_CHARGE; }
                else logger_log(lg, "[%sWarn%s] Agent %c 충전 필요하나 충전소 사용중.", C_YEL, C_NRM, ag->symbol);
                continue;
            }
            if (sc->mode == MODE_CUSTOM) {
                if (sc->current_phase_index >= sc->num_phases) continue;
                DynamicPhase* ph = &sc->phases[sc->current_phase_index];
                if (ph->type == PARK_PHASE) {
                    int active = 0; for (int j = 0; j < MAX_AGENTS; j++) {
                        AgentState s = am->agents[j].state;
                        if (s == GOING_TO_PARK || s == RETURNING_HOME_EMPTY) active++;
                    }
                    if ((sc->tasks_completed_in_phase + active) < ph->task_count && am->total_cars_parked < map->num_goals) {
                        g_agent_ops.beginTaskPark(ag, sc, lg);
                    }
                }
                else {
                    int active = 0; for (int j = 0; j < MAX_AGENTS; j++) {
                        AgentState s = am->agents[j].state;
                        if (s == GOING_TO_COLLECT || s == RETURNING_WITH_CAR) active++;
                    }
                    if ((sc->tasks_completed_in_phase + active) < ph->task_count && am->total_cars_parked > 0) {
                        g_agent_ops.beginTaskExit(ag, sc, lg);
                    }
                }
            }
            else if (sc->mode == MODE_REALTIME && sc->task_count > 0) {
                int lot_full = (am->total_cars_parked >= map->num_goals);
                TaskNode* cur = sc->task_queue_head; TaskNode* prev = NULL;
                while (cur) {
                    int can = FALSE;
                    if (lot_full) {
                        if (cur->type == TASK_EXIT && am->total_cars_parked > 0) can = TRUE;
                    }
                    else {
                        if (cur->type == TASK_PARK) can = TRUE;
                        else if (cur->type == TASK_EXIT && am->total_cars_parked > 0) can = TRUE;
                    }
                    if (can) {
                        if (cur->type == TASK_PARK) { g_agent_ops.beginTaskPark(ag, sc, lg); }
                        else { g_agent_ops.beginTaskExit(ag, sc, lg); }
                        if (prev == NULL) sc->task_queue_head = cur->next; else prev->next = cur->next;
                        if (cur == sc->task_queue_tail) sc->task_queue_tail = prev;
                        free(cur); sc->task_count--; break;
                    }
                    prev = cur; cur = cur->next;
                }
            }
        }
    }
}

// --- One-step executor: encapsulates a single simulation tick without input/pause handling ---
/**
 * @brief 입력/일시정지 처리 없이 순수 한 틱을 실행합니다.
 *        (충전/상태갱신 → 계획 → 이동적용 → 상태전이 → 메트릭/렌더)
 * @param sim 시뮬레이션 인스턴스
 * @param is_paused 일시정지 플래그(표시용)
 */
static void simulation_execute_one_step(Simulation* sim, int is_paused) {
    ScenarioManager* sc = sim->scenario_manager;
    int phase_idx_for_step = sc->current_phase_index;
    int step_label = sc->time_step + 1;
    int is_custom_mode = (sc->mode == MODE_CUSTOM);
    int phase_active = (is_custom_mode && phase_idx_for_step >= 0 && phase_idx_for_step < sc->num_phases);
    int cleanup_region = (is_custom_mode && phase_idx_for_step >= sc->num_phases);

    clock_t step_start_cpu = clock();

    agent_manager_update_charge_state(sim->agent_manager, sim->map, sim->logger);
    simulation_update_state(sim);

    Node* next_pos[MAX_AGENTS];
    Node* prev_pos[MAX_AGENTS];
    for (int i = 0; i < MAX_AGENTS; i++) prev_pos[i] = sim->agent_manager->agents[i].pos;

    // 계획 단계 캡슐화
    simulation_plan_step(sim, next_pos);

    // 회전 대기(TURN_90_WAIT) 적용: 모든 알고리즘 공통 처리
    {
        AgentManager* am = sim->agent_manager;
        for (int i = 0; i < MAX_AGENTS; i++) {
            Agent* ag = &am->agents[i];
            if (ag->state == CHARGING) continue;
            Node* current = ag->pos;
            if (!current || !next_pos[i]) continue;
            if (ag->rotation_wait > 0) {
                next_pos[i] = current;
                ag->rotation_wait--;
                continue;
            }
            Node* adjusted = current;
            agent_apply_rotation_and_step(ag, current, next_pos[i], &adjusted);
            next_pos[i] = adjusted;
        }

        // 회전 대기 중인 에이전트 칸 진입 금지(통과 방지)
        for (int i = 0; i < MAX_AGENTS; i++) {
            Agent* blocker = &am->agents[i];
            if (!blocker->pos) continue;
            if (blocker->rotation_wait <= 0) continue;
            Node* blocked_cell = blocker->pos;
            for (int j = 0; j < MAX_AGENTS; j++) {
                if (j == i) continue;
                Agent* mover = &am->agents[j];
                if (!mover->pos || !next_pos[j]) continue;
                if (next_pos[j] == blocked_cell && mover->pos != blocked_cell) {
                    next_pos[j] = mover->pos; // 대기 처리
                }
            }
        }

        // 추가 안전장치: 이번 틱에 "정지"하는 에이전트의 현재 칸으로 진입 금지
        // (회전 대기 외에도 작업 대기 등으로 정지하는 경우 포함)
        for (int i = 0; i < MAX_AGENTS; i++) {
            Agent* stopper = &am->agents[i];
            if (!stopper->pos) continue;
            if (!next_pos[i]) continue;
            if (next_pos[i] != stopper->pos) continue; // 움직이는 에이전트는 제외
            Node* blocked_cell = stopper->pos;
            for (int j = 0; j < MAX_AGENTS; j++) {
                if (j == i) continue;
                Agent* mover = &am->agents[j];
                if (!mover->pos || !next_pos[j]) continue;
                if (next_pos[j] == blocked_cell && mover->pos != blocked_cell) {
                    next_pos[j] = mover->pos; // 대기 처리
                }
            }
        }
    }

    // 회전 보정 및 차단 로직 적용 이후, 최종 쌍대 충돌 정리를 한 번 더 수행(전 알고리즘 공통)
    {
        int order[MAX_AGENTS];
        sort_agents_by_priority(sim->agent_manager, order);
        resolve_conflicts_by_order(sim->agent_manager, order, next_pos);
    }

    int moved_this_step = apply_moves_and_update_stuck(sim, next_pos, prev_pos);

    unsigned long long prev_completed_tasks = sim->tasks_completed_total;
    agent_manager_update_state_after_move(sim->agent_manager, sim->scenario_manager, sim->map, sim->logger, sim);
    if (sim->tasks_completed_total != prev_completed_tasks) {
        sim->last_task_completion_step = step_label;
    }

    clock_t step_end_cpu = clock();
    double step_time_ms = ((double)(step_end_cpu - step_start_cpu) * 1000.0) / CLOCKS_PER_SEC;
    sim->last_step_cpu_time_ms = step_time_ms;
    sim->total_cpu_time_ms += step_time_ms;
    if (step_time_ms > sim->max_step_cpu_time_ms) {
        sim->max_step_cpu_time_ms = step_time_ms;
    }
    if (is_custom_mode) {
        if (phase_active) {
            int idx = phase_idx_for_step;
            if (idx >= 0 && idx < MAX_PHASES) {
                if (sim->phase_step_counts[idx] == 0) {
                    sim->phase_first_step[idx] = step_label;
                }
                sim->phase_last_step[idx] = step_label;
                sim->phase_step_counts[idx]++;
                sim->phase_cpu_time_ms[idx] += step_time_ms;
            }
        }
        else if (cleanup_region) {
            if (sim->post_phase_step_count == 0) {
                sim->post_phase_first_step = step_label;
            }
            sim->post_phase_last_step = step_label;
            sim->post_phase_step_count++;
            sim->post_phase_cpu_time_ms += step_time_ms;
            // 모든 단계가 끝난 뒤 일정 스텝이 지나도 잔여 에이전트가 남아있으면 강제 유휴화로 교착 해소
            if (sim->post_phase_step_count >= CLEANUP_FORCE_IDLE_AFTER_STEPS) {
                force_idle_cleanup(sim->agent_manager, sim, sim->logger);
            }
        }
    }

    update_deadlock_counter(sim, moved_this_step, is_custom_mode);

    accumulate_wait_ticks_if_realtime(sim);

    // 알고리즘 단계 샘플만 집계
    simulation_collect_memory_sample_algo(sim);
    // 전체 프로세스 메모리 사용량 샘플 집계
    simulation_collect_memory_sample(sim);
    sim->total_executed_steps = step_label;

    // 프레임 갱신 (프레임 스킵은 renderer 내부에서 처리됨)
    sim->renderer.vtbl.draw_frame(sim, is_paused);
}

// 모든 에이전트를 강제로 IDLE 상태로 전환하여 정리 단계에서의 교착을 해소한다
static void force_idle_cleanup(AgentManager* am, Simulation* sim, Logger* lg) {
    if (!am) return;
    int changed = 0;
    for (int i = 0; i < MAX_AGENTS; i++) {
        Agent* ag = &am->agents[i];
        if (!ag->pos) continue;
        if (ag->state == IDLE) continue;
        if (ag->goal) { ag->goal->reserved_by_agent = -1; ag->goal = NULL; }
        if (ag->pf) { pathfinder_destroy(ag->pf); ag->pf = NULL; }
        ag->rotation_wait = 0;
        ag->stuck_steps = 0;
        ag->action_timer = 0;
        ag->state = IDLE;
        changed = 1;
    }
    if (changed && lg) {
        logger_log(lg, "[%sCleanup%s] 모든 에이전트를 강제 IDLE로 전환하여 교착을 해소했습니다.", C_B_CYN, C_NRM);
    }
}
/**
 * @brief 시뮬레이션 종료 조건(커스텀: 모든 단계 완료, 실시간: 시간 제한)을 확인합니다.
 * @param sim 시뮬레이션 인스턴스
 * @return 종료:TRUE, 계속:FALSE
 */
static int simulation_is_complete(const Simulation* sim) {
    const ScenarioManager* sc = sim->scenario_manager;
    const AgentManager* am = sim->agent_manager;
    if (sc->mode == MODE_CUSTOM && sc->current_phase_index >= sc->num_phases) {
        for (int i = 0; i < MAX_AGENTS; i++) if (am->agents[i].state != IDLE) return FALSE;
        printf(C_B_GRN "\n모든 단계 완료! 종료합니다.\n" C_NRM); return TRUE;
    }
    if (sc->mode == MODE_REALTIME && sc->time_step >= REALTIME_MODE_TIMELIMIT) {
        printf(C_B_GRN "\n시간 제한 도달! 종료합니다.\n" C_NRM); return TRUE;
    }
    return FALSE;
}

/**
 * @brief 메인 루프: 비동기 입력(P/S/±/[]/F/C/Q) 처리와 한 틱 실행을 반복합니다.
 * @param sim 시뮬레이션 인스턴스
 */
void simulation_run(Simulation* sim) {
    ControlState cs; 
    ControlState_init(&cs);

    simulation_reset_runtime_stats(sim);

    // 시뮬레이션 시작 전, 초기 상태를 한 번 그림
    sim->renderer.vtbl.draw_frame(sim, cs.is_paused);

    while (!cs.quit_flag) {
        // --- 입력 처리 ---
        cs.last_key = check_for_input();
        if (cs.last_key) {
            ui_handle_control_key(sim, cs.last_key, &cs.is_paused, &cs.quit_flag);
            sim->renderer.vtbl.draw_frame(sim, cs.is_paused);
            if (cs.quit_flag) continue;
        }

        // --- 일시정지 로직 ---
        // 일시정지 상태이고, 's'키가 입력되지 않았다면 시뮬레이션 로직을 건너뜀
        if (cs.is_paused && tolower(cs.last_key) != 's') {
            sleep_ms(PAUSE_POLL_INTERVAL_MS);
            continue;
        }

        // --- 한 스텝 실행 ---
        simulation_execute_one_step(sim, cs.is_paused);

        if (simulation_is_complete(sim)) {
            break;
        }

        maybe_report_realtime_dashboard(sim);

        if (sim->scenario_manager->simulation_speed > 0) sleep_ms(sim->scenario_manager->simulation_speed);
    }
}

/**
 * @brief 실행 결과(스텝/처리량/이동거리/메모리/단계별 요약)를 출력합니다.
 * @param sim 시뮬레이션 인스턴스
 */
void simulation_print_performance_summary(const Simulation* sim) {
    const ScenarioManager* sc = sim->scenario_manager;
    const AgentManager* am = sim->agent_manager;
    const int recorded_steps = (sim->total_executed_steps > 0) ? sim->total_executed_steps : (sc ? sc->time_step : 0);
    const double avg_cpu_ms = (recorded_steps > 0) ? (sim->total_cpu_time_ms / (double)recorded_steps) : 0.0;
    const double avg_plan_ms = (recorded_steps > 0) ? (sim->total_planning_time_ms / (double)recorded_steps) : 0.0;
    const double throughput = (recorded_steps > 0) ? ((double)sim->tasks_completed_total / (double)recorded_steps) : 0.0;
    const double avg_memory_kb = (sim->memory_samples > 0) ? (sim->memory_usage_sum_kb / (double)sim->memory_samples) : 0.0;

    const char* mode_label = "Uninitialized";
    if (sc) {
        switch (sc->mode) {
        case MODE_CUSTOM: mode_label = "Custom"; break;
        case MODE_REALTIME: mode_label = "Real-Time"; break;
        default: mode_label = "Uninitialized"; break;
        }
    }

    printf("\n============================================\n");
    printf("          Simulation Result Report\n");
    printf("============================================\n");
    printf(" Mode                                : %s\n", mode_label);
    printf(" Map ID                              : %d\n", sim->map_id);
    {
        const char* algo = "Default (WHCA* + D* Lite + WFG + CBS)";
        if (sim->path_algo == PATHALGO_ASTAR_SIMPLE) algo = "A* (단순)";
        else if (sim->path_algo == PATHALGO_DSTAR_BASIC) algo = "D* Lite (기본)";
        printf(" Path Planning Algorithm             : %s\n", algo);
    }
    printf(" Total Physical Time Steps           : %d\n", recorded_steps);
    {
        int active_agents = 0;
        if (am) {
            for (int i = 0; i < MAX_AGENTS; i++) if (am->agents[i].pos) active_agents++;
        }
        printf(" Operating AGVs                     : %d\n", active_agents);
    }

    printf(" Tasks Completed (total)             : %llu\n", sim->tasks_completed_total);
    printf(" Throughput [task / total physical time] : %.4f\n", throughput);
    printf(" Total Movement Cost (cells)         : %.2f\n", sim->total_movement_cost);

    printf(" Requests Created (total)            : %llu\n", sim->requests_created_total);
    printf(" Request Wait Ticks (sum)            : %llu\n", sim->request_wait_ticks_sum);
    printf(" Process Memory Usage Sum            : %.2f KB\n", sim->memory_usage_sum_kb);
    printf(" Process Memory Usage Average        : %.2f KB\n", avg_memory_kb);
    printf(" Process Memory Usage Peak           : %.2f KB\n", sim->memory_usage_peak_kb);
    printf(" Remaining Parked Vehicles           : %d\n", am ? am->total_cars_parked : 0);
    printf("\n -- 알고리즘 연산 메트릭 --\n");
    printf(" Nodes Expanded (total)             : %llu\n", sim->algo_nodes_expanded_total);
    printf(" Heap Moves (total)                  : %llu\n", sim->algo_heap_moves_total);
    printf(" Generated Nodes (total)            : %llu\n", sim->algo_generated_nodes_total);
    printf(" Valid Expansions (total)           : %llu\n", sim->algo_valid_expansions_total);
    double valid_ratio_total = (sim->algo_generated_nodes_total > 0) ? (double)sim->algo_valid_expansions_total / (double)sim->algo_generated_nodes_total : 0.0;
    printf(" Valid Expansion Ratio (valid/gen) : %.4f\n", valid_ratio_total);
    if (recorded_steps > 0) {
        const double avg_nodes_per_step = (double)sim->algo_nodes_expanded_total / (double)recorded_steps;
        const double avg_heap_moves_per_step = (double)sim->algo_heap_moves_total / (double)recorded_steps;
        const double avg_generated_per_step = (double)sim->algo_generated_nodes_total / (double)recorded_steps;
        const double avg_valid_per_step = (double)sim->algo_valid_expansions_total / (double)recorded_steps;
        printf(" Nodes Expanded (avg per step)      : %.2f\n", avg_nodes_per_step);
        printf(" Heap Moves (avg per step)          : %.2f\n", avg_heap_moves_per_step);
        printf(" Generated Nodes (avg per step)     : %.2f\n", avg_generated_per_step);
        printf(" Valid Expansions (avg per step)    : %.2f\n", avg_valid_per_step);
    }

    if (sc && sc->mode == MODE_CUSTOM) {
        printf("\n -- Custom Scenario Breakdown --\n");
        for (int i = 0; i < sc->num_phases; i++) {
            const DynamicPhase* ph = &sc->phases[i];
            const int planned = ph->task_count;
            const int completed = sim->phase_completed_tasks[i];
            const int step_count = sim->phase_step_counts[i];
            printf(" Phase %d (%s)\n", i + 1, ph->type_name);
            printf("   Planned Tasks           : %d\n", planned);
            printf("   Completed Tasks         : %d\n", completed);
            if (step_count > 0) {
                printf("   Step Span               : %d step(s)", step_count);
                if (sim->phase_first_step[i] >= 0 && sim->phase_last_step[i] >= 0) {
                    printf(" [#%d -> #%d]\n", sim->phase_first_step[i], sim->phase_last_step[i]);
                }
                else {
                    printf("\n");
                }
                const double phase_avg_cpu = sim->phase_cpu_time_ms[i] / (double)step_count;
                printf("   CPU Time                : %.2f ms (avg %.4f ms/step)\n",
                    sim->phase_cpu_time_ms[i], phase_avg_cpu);
            }
            else {
                printf("   Step Span               : N/A\n");
            }
            if (completed < planned) {
                printf("   Remaining Tasks         : %d\n", planned - completed);
            }
        }
    }
    else if (sc && sc->mode == MODE_REALTIME) {
        printf("\n -- Custom Scenario Breakdown --\n");
        // Real-Time 모드: 단일 집계 구간으로 동일 포맷 제공
        printf(" Phase 1 (%s)\n", "Real-Time");
        printf("   Planned Tasks           : %d\n", (int)sim->tasks_completed_total);
        printf("   Completed Tasks         : %d\n", (int)sim->tasks_completed_total);
        if (recorded_steps > 0) {
            printf("   Step Span               : %d step(s) [#%d -> #%d]\n", recorded_steps, 1, recorded_steps);
            const double phase_avg_cpu = sim->total_cpu_time_ms / (double)recorded_steps;
            printf("   CPU Time                : %.2f ms (avg %.4f ms/step)\n", sim->total_cpu_time_ms, phase_avg_cpu);
        }
        else {
            printf("   Step Span               : N/A\n");
            printf("   CPU Time                : 0.00 ms (avg 0.0000 ms/step)\n");
        }
    }

    printf("============================================\n");
}

// =============================================================================
// 섹션 11: 시뮬레이션 생명주기 (생성/파괴) 및 메인 진입점
// =============================================================================
Simulation* simulation_create() {
    Simulation* s = (Simulation*)calloc(1, sizeof(Simulation)); if (!s) { perror("Simulation"); exit(1); }
    s->agent_manager = agent_manager_create();
    s->map = grid_map_create(s->agent_manager); // default map #1
    s->scenario_manager = scenario_manager_create();
    s->logger = logger_create();
    s->map_id = 1; // 현재 맵 = 1번
    s->path_algo = PATHALGO_DEFAULT;
    s->planner = planner_from_pathalgo(s->path_algo);
    s->renderer = renderer_create_facade();
    g_metrics.whca_h = g_whca_horizon;
    GlobalConfig_init(&g_config);
    metrics_subscribe(simulation_metrics_observer, s);
    return s;
}
void simulation_destroy(Simulation* s) {
    if (s) {
        grid_map_destroy(s->map);
        agent_manager_destroy(s->agent_manager);
        scenario_manager_destroy(s->scenario_manager);
        logger_destroy(s->logger);
        free(s);
    }
}
int main() {
    srand((unsigned int)time(NULL));
    system_enable_virtual_terminal();
    ensure_console_width(180);


    Simulation* sim = simulation_create();
    if (!sim) return 1;

    if (simulation_setup(sim)) {
        ui_enter_alt_screen();     // ALT 스크린 진입
        simulation_run(sim);       // 프레임 갱신해도 스크롤백 오염 없음
        ui_leave_alt_screen();     // ALT 스크린 종료(원래 화면 복귀)
        simulation_print_performance_summary(sim);
        printf("\n결과를 확인하려면 아무 키나 누르세요...\n");
        (void)_getch();
    }
    else {
        printf("\n시뮬레이션이 취소되었습니다. 종료합니다.\n");
    }


    simulation_destroy(sim);
    return 0;
}
