#define MAX_INST 256
#define MAX_LINES 5000

#define MAX_COLUMNS 4
#define MAX_OPERAND 3

/*새로 추가한 define*/
#define MAX_SEC 3 // file section 3개 MAX 추가 가능

 /*
 * instruction 목록을 저장하는 구조체이다.
 * instruction 목록 파일로부터 정보를 받아와서 생성한다.
 * instruction 목록 파일에는 라인별로 하나의 instruction을 저장한다.
 *
 */
typedef struct _inst
{
	char str[10];//name
	unsigned char op;//opcode
	int format;//formant
	int ops;//number of oprend
} inst;


// 기계어를 관리하는 테이블
inst* inst_table[MAX_INST];
int inst_index;


// 어셈블리 할 소스코드를 파일로부터 불러와 라인별로 관리하는 테이블
char* input_data[MAX_LINES];
static int line_num;

int label_num;
/*
 * 어셈블리 할 소스코드를 토큰으로 변환하여 저장하는 구조체 변수이다.
 * operator 변수명은 renaming을 허용한다.
 */
typedef struct _token {
	char* label;
	char* operator;
	char* operand[MAX_OPERAND];
	char comment[100];
	char nixbpe;
} token;

// 어셈블리 할 소스코드를 5000라인까지 관리하는 테이블
token* token_table[MAX_LINES];
static int token_line;

/*
 * 심볼을 관리하는 구조체이다.
 * 심볼 테이블은 심볼 이름, 심볼의 위치로 구성된다.
 */
typedef struct _symbol
{
	char symbol[10];
	int addr;
} symbol;

/*
* 리터럴을 관리하는 구조체이다.
* 리터럴 테이블은 리터럴의 이름, 리터럴의 위치로 구성된다.
*/
typedef struct _literal {
	char* literal;
	int addr;
} literal;

symbol sym_table[MAX_LINES];
static int sym_index;

literal literal_table[MAX_LINES];
static int literal_index;

/**
 * 오브젝트 코드 전체에 대한 정보를 담는 구조체이다.
 * Header Record, Define Recode,
 * Modification Record 정보가 들어있다.
 */
typedef struct _object_code {
	// H' line  
	char p_name[7];//program name
	int h_start_addr;//start adress
	int p_length;//program length

	//D' line
	char d_name[10][7];//10개??
	int d_addr[10];

	//R' line
	char r_name[10][7];

	//T' line
	int t_staddr[MAX_LINES];//each line  start address
	int t_addr[MAX_LINES];//each addr
	int t_length[MAX_LINES]; //each line length
	int t_code[MAX_LINES];//code
	int t_format[MAX_LINES];

	// M' line
	int m_addr[MAX_LINES];
	int m_length[MAX_LINES];
	char* m_name[MAX_LINES];
	char m_sign[MAX_LINES];

} object_code;
object_code code[MAX_SEC];

static int locctr;

static char* input_file;
static char* output_file;

/*새로 추가한 변수*/
static int token_table_addr[MAX_LINES];//보고서에 적어야함 TA - PC를 위해서
static int sym_len[MAX_SEC];//symbol 검색 범위
static int sec_len[MAX_SEC] = { 0, };//section별 length

int init_my_assembler(void);
int init_inst_file(char* inst_file);
int init_input_file(char* input_file);
int token_parsing(char* str);
int search_opcode(char* str);
static int assem_pass1(void);
void make_opcode_output(char* file_name);
void make_symtab_output(char* file_name);
void make_literaltab_output(char* filename);
static int assem_pass2(void);
void make_objectcode_output(char* file_name);

/*새로 추가한 함수*/
int split_tap(char* data, char* arr[]);// tap 제거
int split_comma(char* data, char* arr[]);// comma 제거
int literal_check(char* temp);// literal 중복 체크
int search_opcode(char* str);//operator -> opcode로 반환

void split_table();//symbol table split
int reg_num(char c);//register table
int search_sym(char* s, int mode);//symbol search return symbol address
int search_lit(char* s);//literal search return address