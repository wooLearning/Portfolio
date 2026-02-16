import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * 모든 instruction의 정보를 관리하는 클래스.
 * Assembler에서 사용한 클래스 변형
 */
public class InstTable {
	
    /** opcode(정수) → Instruction 정보 */
    private final Map<Integer,Instruction> instMap;

    /**
     * 파싱과 동시에 instMap을 초기화
     * @param instFile : 명세 파일 경로
     */
    public InstTable(String instFile) {
        instMap = new HashMap<>();
        openFile(instFile);
    }

    /**
     * 파일을 열어 한 줄씩 파싱하고 instMap에 저장
     */
    private void openFile(String fileName) {
        try (BufferedReader br = new BufferedReader(new FileReader(fileName))) {
            String line;
            while ((line = br.readLine()) != null) {
                Instruction inst = new Instruction(line);
                instMap.put(inst.opcode, inst);
//              System.out.printf("Loaded opcode 0x%02X → %s%n",inst.opcode, inst.mnemonic);
            }
        } catch (IOException e) {
            throw new RuntimeException("Error reading inst file “" + fileName + "”: " + e.getMessage(), e);
        }
    }

    /** opcode로 Instruction 객체를 꺼냅니다. */
    public Instruction getInstruction(int opcode) {
        return instMap.get(opcode);
    }
    
    /** opcode로부터 format return */
    public int getFormat(int opcode) {
        Instruction inst = instMap.get(opcode);
        if (inst == null) return -1;
        return inst.format;
    }
}

/**
 * 명령어 하나하나의 구체적인 정보는 Instruction클래스에 담깁니다.
 */
class Instruction {
    public String  mnemonic;     // 예: "LDA"
    public int     format;       // 1,2,3,4
    public int     opcode;       // 예: 0x00
    public int     operandCount; // 예: 2

    /**
     * "LDA 3 00 2" 같은 한 줄을 파싱
     * parts[0]=mnemonic, parts[1]=format, parts[2]=opcode(16진수), parts[3]=operandCount
     */
    public Instruction(String line) {
        String[] parts = line.trim().split("\\s+");
        if (parts.length < 4) {
            throw new IllegalArgumentException("Invalid instruction entry: " + line);
        }
        mnemonic     = parts[0];
        format       = Integer.parseInt(parts[1]);
        opcode       = Integer.parseInt(parts[2], 16);
        operandCount = Integer.parseInt(parts[3]);
    }
}
