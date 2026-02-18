import java.io.File;
import java.util.ArrayList;

/**
 * 시뮬레이터로서의 작업을 담당한다. VisualSimulator에서 사용자의 요청을 받으면 이에 따라 ResourceManager에 접근하여
 * 작업을 수행한다.
 * 
 * 작성중의 유의사항 : 1) 새로운 클래스, 새로운 변수, 새로운 함수 선언은 얼마든지 허용됨. 단, 기존의 변수와 함수들을 삭제하거나
 * 완전히 대체하는 것은 지양할 것. 2) 필요에 따라 예외처리, 인터페이스 또는 상속 사용 또한 허용됨. 3) 모든 void 타입의 리턴값은
 * 유저의 필요에 따라 다른 리턴 타입으로 변경 가능. 4) 파일, 또는 콘솔창에 한글을 출력시키지 말 것. (채점상의 이유. 주석에 포함된
 * 한글은 상관 없음)
 * 
 * + 제공하는 프로그램 구조의 개선방법을 제안하고 싶은 분들은 보고서의 결론 뒷부분에 첨부 바랍니다. 내용에 따라 가산점이 있을 수
 * 있습니다.
 */
public class SicSimulator {
	ResourceManager rMgr;
	SicLoader loader;
	
	int target_address;
	String inst_field;//Log 기록용
	
	public ArrayList<String> logs = new ArrayList<>();
	InstLuncher instluncher;
	
	public SicSimulator(ResourceManager resourceManager) {
		// 필요하다면 초기화 과정 추가
		this.rMgr = resourceManager;
		this.loader = new SicLoader(resourceManager);
		this.instluncher = new InstLuncher(resourceManager);
	}

	/**
	 * 레지스터, 메모리 초기화 등 프로그램 load와 관련된 작업 수행. 단, object code의 메모리 적재 및 해석은
	 * SicLoader에서 수행하도록 한다.
	 */
	public void load(File program) {
		/* 메모리 초기화, 레지스터 초기화 등 */
		rMgr.initializeResource();
		loader.load(program);
		target_address = 0;
	}
	
	public String charToString(char[] a) {
        StringBuilder sb = new StringBuilder();
        for (char b : a) {
            sb.append(String.format("%02X", (int)b & 0xFF));
        }
        String hexInstr = sb.toString();
        return hexInstr;
    }
	/**
	 * 1개의 instruction이 수행된 모습을 보인다.
	 */
	public void oneStep() {
		int operand = 0;
        int pc = rMgr.getRegister(8);
        
        char[] a = rMgr.getMemory(pc,3);
        
        String hexInstr = charToString(a);//hex instruction 변수
        
        int inst = Integer.parseInt(hexInstr,16);//string -> int
        int nixbpe = (inst)>>12 & 0x3f;
        
        int op_format2 = (inst)>>16;//op 8bit(6bit + 2bit) format2 처리
        
        int op = ((inst)>>16) & 0xFC;//1111_1100
   		int value=0;
   		
   		boolean isImediate = false;
   		
        if(rMgr.inst.getFormat(op_format2) == 2) {//format 2
        	pc+=2;
        	rMgr.setRegister(8, pc);
        	inst_field = hexInstr.substring(0,4);
        	isImediate = false;
        	Instruction temp_inst = rMgr.inst.getInstruction(op_format2);
        	inst = inst>>8;
        	
        	int reg1, reg2;
        	
        	reg1 = (inst>>4) & 0x0f;
        	reg2 = inst & 0x0f;
        	
        	exec(temp_inst.mnemonic,0,reg1,reg2,pc,isImediate);
        	return;
    	}//////////format 4, 3 처리
        else if((nixbpe & 1) == 1) {//format 4
    		char[] a2 = rMgr.getMemory(pc+3,1);
            hexInstr += charToString(a2);
            inst = Integer.parseInt(hexInstr,16);
            inst_field = hexInstr;
            pc+=4;
            rMgr.setRegister(8, pc);
            operand = inst & 0xFFFFF;// 3byte opeanrd
            
    		if((nixbpe & 0x30) == 16) {//immediate
    			value = operand;
    			isImediate = true;
    		}else {
    			if((nixbpe & 0x02) == 2) {//pc relative
        			target_address = pc + operand;
        		}else {
        			target_address = operand;
        		}
    			
    			value = target_address;
    		}
    		
    		if( (nixbpe & 8) == 8 ) {//x bit 확인
    			value += rMgr.getRegister(1);
    		}
    		
            Instruction temp_inst2 = rMgr.inst.getInstruction(op);
            exec(rMgr.inst.getInstruction(op).mnemonic,value,0,0,pc,isImediate);
            
    	}else if(rMgr.inst.getFormat(op) == 3){//format 3
    		pc+=3;
    		rMgr.setRegister(8, pc);
    		inst_field = hexInstr;
    		operand = inst & 0xFFF;//3byte operand
    		
    		if ((operand  & 0x800) != 0) {
    			operand |= ~0xFFF;//signed extension
    		}
    		if((nixbpe & 0x30) == 16) {//immediate
    			value = operand;
    			isImediate = true;
    		}else if((nixbpe & 0x30) == 32) {
    			if((nixbpe & 0x02) == 2) {//pc relative
        			target_address = pc + operand;
        		}else {
        			target_address = operand;
        		}
    			value = target_address; 
    			value = Integer.parseInt(charToString(rMgr.getMemory(target_address,3)),16);
    		}
    		else {
    			if((nixbpe & 0x02) == 2) {//pc relative
        			target_address = pc + operand;
        		}else {
        			target_address = operand;
        		}
    			value = target_address;    			
    		}
    		
            Instruction temp_inst2 = rMgr.inst.getInstruction(op);
            exec(rMgr.inst.getInstruction(op).mnemonic,value,0,0,pc,isImediate);
            
    	}else {
    		System.err.println("wrong op");
    	}
 
	}

	
	/**
	 * 각 단계를 수행할 때 마다 관련된 기록을 남기도록 한다.
	 */
	public void addLog(String log) {
		logs.add(log);
	}
	
	//instLuncher 실행전 분배
	public void exec(String op, int addr, int reg1, int reg2,int pc,boolean isImediate) {
		addLog(op);
		
		if (op.equals("STL")) {
		    instluncher.STL(addr);
		}
		else if (op.equals("JSUB")) {
		    instluncher.JSUB(addr,pc);
		}
		else if (op.equals("LDA")) {
		    instluncher.LDA(addr, isImediate);
		}
		else if (op.equals("COMP")) {
		    instluncher.COMP(addr,isImediate);
		}
		else if (op.equals("COMPR")) {
		    instluncher.COMPR(reg1, reg2);
		}
		else if (op.equals("JEQ")) {
		    instluncher.JEQ(addr);
		}
		else if (op.equals("J")) {
		    instluncher.J(addr);
		}
		else if (op.equals("STA")) {
		    instluncher.STA(addr);
		}
		else if (op.equals("CLEAR")) {
		    instluncher.CLEAR(reg1); // here value is actually a register number
		}
		else if (op.equals("LDT")) {
		    instluncher.LDT(addr,isImediate);// value holds the constant or address
		}
		else if (op.equals("TD")) {
		    instluncher.TD(addr);
		}
		else if (op.equals("RD")) {
		    instluncher.RD(addr);
		}
		else if (op.equals("WD")) {
		    instluncher.WD(addr);
		}
		else if (op.equals("STCH")) {
		    instluncher.STCH(addr);
		}
		else if (op.equals("TIXR")) {
		    instluncher.TIXR();
		}
		else if (op.equals("JLT")) {
		    instluncher.JLT(addr);
		}
		else if (op.equals("STX")) {
		    instluncher.STX(addr);
		}
		else if (op.equals("RSUB")) {
			instluncher.RSUB();
		}else if(op.equals("LDCH")) {
			
			instluncher.LDCH(addr,isImediate);
		}else {
		    throw new IllegalArgumentException("Unknown instruction: " + op);
		}
	 }
}
