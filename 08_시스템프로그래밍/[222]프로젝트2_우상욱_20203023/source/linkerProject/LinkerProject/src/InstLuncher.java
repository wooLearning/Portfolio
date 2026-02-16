// instruction에 따라 동작을 수행하는 메소드를 정의하는 클래스

public class InstLuncher {
    ResourceManager rMgr;

    public InstLuncher(ResourceManager resourceManager) {
        this.rMgr = resourceManager;
    }
    
    public String charToString(char[] a) {
        StringBuilder sb = new StringBuilder();
        for (char b : a) {
            sb.append(String.format("%02X", (int)b & 0xFF));
        }
        String hexInstr = sb.toString();
        return hexInstr;
    }
    
    // instruction 별로 동작을 수행하는 메소드를 정의
    // ex) public void add(){...}
    public void STL(int addr) {
    	char[] bytes = rMgr.intToChar(rMgr.getRegister(2));
    	rMgr.setMemory(addr,bytes,bytes.length);
    }
    
    public void JSUB(int addr,int addr_return) {
    	rMgr.setRegister(8, addr);//pc 값 업데이트
    	rMgr.setRegister(2, addr_return);
    }  
    
    public void LDA(int addr,boolean isImediate) {
    	int value = (isImediate) ? addr : Integer.parseInt(charToString(rMgr.getMemory(addr,3)),16);
    	rMgr.setRegister(0, value);
    	//System.out.printf("%x %x\n",value, addr);
    }
    
    public void COMP(int addr,boolean isImediate) {
    	int value = (isImediate) ? addr : Integer.parseInt(charToString(rMgr.getMemory(addr,3)),16);
    	
    	if( (rMgr.getRegister(0) == value) ) {//eqaul 
    		rMgr.setRegister(9, 1);
    	}else if(rMgr.register[0] > value) {//GT
    		rMgr.setRegister(9, 2);
    	}
    	else if(rMgr.register[0] < value) {//LT
    		rMgr.setRegister(9, 3);
    	}
    	else {
    		rMgr.setRegister(9, 0);
    	}
    }
    
    public void JEQ(int addr) {
    	if(rMgr.getRegister(9) == 1) {
    		rMgr.setRegister(8, addr);//pc=8
    	}
    }
    public void J(int addr) {
    	rMgr.setRegister(8, addr);
    }
    
    public void STA(int addr) {
    	char[] bytes = rMgr.intToChar(rMgr.getRegister(0));
    	rMgr.setMemory(addr,bytes,3);
    }
    
    public void CLEAR(int reg) {
       	rMgr.setRegister(reg, 0);
    }
    
    public void LDT(int addr, boolean isImediate) {
    	int value = (isImediate) ? addr : Integer.parseInt(charToString(rMgr.getMemory(addr,3)),16);
    	rMgr.setRegister(5, value);
    }
    
    public void COMPR(int reg1, int reg2) {
    	if( ( rMgr.getRegister(reg1) == rMgr.getRegister(reg2) ) ) {//eqaul 
    		 rMgr.setRegister(9, 1);
    	}else if( ( rMgr.getRegister(reg1) > rMgr.getRegister(reg2) ) ) {//GT
    		rMgr.setRegister(9, 2);
    	}else if( ( rMgr.getRegister(reg1) < rMgr.getRegister(reg2) ) ) {//LT
    		rMgr.setRegister(9, 3);
    	}
    	else {
    		rMgr.setRegister(9, 0);
    	}
    }
    
    public void TD(int addr) {
    	String dev = charToString(rMgr.getMemory(addr,1));
    	dev+=".txt";
    	rMgr.testDevice(dev);
    }
    
    public void RD(int addr) {
    	String dev = charToString(rMgr.getMemory(addr,1));
    	dev+=".txt";
    	// 1 바이트 읽기
        char[] buf = rMgr.readDevice(dev, 1);
        // unsigned -> int로 바꿔서 A 레지스터에 저장
        int value = buf.length > 0 ? (buf[0] & 0xFF) : 0;
        rMgr.setRegister(0, value);
    }
    
    public void WD(int addr) {
    	 String dev = charToString(rMgr.getMemory(addr,1));
    	 dev+=".txt";
    	 int    aVal = rMgr.getRegister(0) & 0xFF;
         char[] out  = new char[]{ (char)aVal };
         rMgr.writeDevice(dev, out, 1);
    }
    
    public void STCH(int addr) {
    	int value = rMgr.getRegister(0) & 0xFF;//a register의 하위 8bit만
    	char[] temp = new char[] {(char) value};
    	rMgr.setMemory(addr, temp, 1);
    }
    
    public void TIXR() {//x register 증가
    	rMgr.register[1]++;
    	if(rMgr.getRegister(1) < rMgr.getRegister(5)) {//LT
    		rMgr.setRegister(9, 3);
    	}else if(rMgr.getRegister(1) > rMgr.getRegister(5)) {
    		rMgr.setRegister(9, 2);
    	}else {
    		rMgr.setRegister(9, 1);
    	}
    }
    
    public void JLT(int addr) {
    	if(rMgr.getRegister(9) == 3) {
    		rMgr.setRegister(8, addr);//pc <- addr
    	}
    }
    
    public void STX(int addr) {
    	char[] bytes = rMgr.intToChar(rMgr.getRegister(1));
    	rMgr.setMemory(addr,bytes,bytes.length);//memory<-x
    }
    
    public void RSUB() {
    	rMgr.setRegister(8, rMgr.getRegister(2));//L register => pc
    }
    
    public void LDCH(int addr,boolean isImediate) {
    	int value = (isImediate) ? addr : Integer.parseInt(charToString(rMgr.getMemory(addr,1)),16);
    	rMgr.setRegister(0, value);
    }
}