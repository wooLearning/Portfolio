import java.io.File;
import java.util.stream.Collectors;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;
/**
 * SicLoader는 프로그램을 해석해서 메모리에 올리는 역할을 수행한다. 이 과정에서 linker의 역할 또한 수행한다.
 * 
 * SicLoader가 수행하는 일을 예를 들면 다음과 같다. - program code를 메모리에 적재시키기 - 주어진 공간만큼 메모리에 빈
 * 공간 할당하기 - 과정에서 발생하는 symbol, 프로그램 시작주소, control section 등 실행을 위한 정보 생성 및 관리
 */
public class SicLoader {
	ResourceManager rMgr;
	
	String programName;
	
    int startAddress[] = new int[3];//함수 3개
    int programLength[] =  new int[3];
    
    int h_flag = 0;//h section number
    int h_addr=0;//시작 주소 나머지 함수들 보정용
    int whole_length=0;//program 전체 길이
    
    //for text variables////////////////
    ArrayList<String> text = new ArrayList<>();//text 저장용 
    ArrayList<Integer> lineAddrs = new ArrayList<>();//text별 address 저장용
    ArrayList<Integer> text_secs = new ArrayList<>();//text별 section 저장용
    
    
    ///////////////////////////////////
    
    ArrayList<ModifyRecord> modifyRecords = new ArrayList<>();
    
	public SicLoader(ResourceManager resourceManager) {
		setResourceManager(resourceManager);
	}

	/**
	 * Loader와 프로그램을 적재할 메모리를 연결시킨다.
	 * 
	 * @param rMgr
	 */
	public void setResourceManager(ResourceManager resourceManager) {
		this.rMgr = resourceManager;
		this.rMgr.symtabList= new SymbolTable();
	}

	/**
	 * object code를 읽어서 load과정을 수행한다. load한 데이터는 resourceManager가 관리하는 메모리에 올라가도록
	 * 한다. load과정에서 만들어진 symbol table 등 자료구조 역시 resourceManager에 전달한다.
	 * 
	 * @param objectCode 읽어들인 파일
	 */
	public void load(File objectCode) {
		try (BufferedReader br = new BufferedReader(new FileReader(objectCode))) {
            String line;
            while ((line = br.readLine()) != null) {
            	if (line.isEmpty()) continue;
                //System.out.println(line);
                char type = line.charAt(0);
                if(type == 'H') {
                	h_flag++;
                	parseHeader(line);
                }
                if(type == 'T') {
                	parseText(line);
                }else if(type == 'D') {
                	parseDefine(line);
                }else if(type == 'M') {
                	parseModify(line);
                }
               
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
		
		//modify records를 반영하여 text 수정
		modify_text();
		
		//load memory
	    for (int i = 0; i < text.size(); i++) {
	        String instrHex = text.get(i);      // ex: "4B110033"
	        int    startAddr = lineAddrs.get(i); // ex: 0x0010
	        rMgr.loadHex(startAddr, instrHex);
	        //System.out.printf("MEM[%06X] <- %s%n", startAddr, instrHex);
	    }
	    //rMgr.printMemory(0x0000, 100);
		
	}
	void parseHeader(String line) {
		if(h_flag == 1) {
			programName   = line.substring(1,7).trim();
		}
		startAddress[h_flag-1]  = Integer.parseInt(line.substring(7, 13)) + h_addr;
        programLength[h_flag-1] = Integer.parseInt(line.substring(13,19),16);
        whole_length += programLength[h_flag-1];
        String sym = line.substring(1,  7).trim();
        rMgr.symtabList.putSymbol(sym, h_addr,h_flag);//copy RDREC WRREC labael symtable에 저장
        
        h_addr += programLength[h_flag-1];
	}
	void parseDefine(String line) {
        int idx = 1;
        while (idx + 12 <= line.length()) {
            String sym = line.substring(idx, idx + 6).trim();
            int addr= Integer.parseInt(line.substring(idx + 6, idx + 12), 16) + startAddress[h_flag];
            rMgr.symtabList.putSymbol(sym, addr,h_flag);
            idx += 12;
        }
	}
	void parseText(String line) {
		
		int idx = 9;// 1 + 6 + 2;
		int addr = Integer.parseInt(line.substring(5,7),16) + startAddress[h_flag-1];
        while (idx+2 <  line.length()) {
        	String temp = new String();
        	int first = Integer.parseInt(line.substring(idx, idx+2),16);
        	int op = first & (0xFC);//1111_1100
        	
        	int slice = Integer.parseInt(line.substring(idx+1, idx+3),16);
        	int nixbpe = slice & 0x3f;

        	if(rMgr.inst.getFormat(op) == 2) {//format 2
        		temp = line.substring(idx, idx + 4).trim();
        		idx += 4;
        		lineAddrs.add(addr);
        		addr += 2;
        	}else if((nixbpe & 1) == 1) {//format 4
        		temp = line.substring(idx, idx + 8).trim();
        		idx += 8;
        		lineAddrs.add(addr);
        		addr += 4;
        	}else if(rMgr.inst.getFormat(op) == 3){ // format 3
        		temp = line.substring(idx, idx + 6).trim();
        		idx += 6;
        		lineAddrs.add(addr);
        		addr += 3;
        	}else if(first == 0xF1) {//f1 일때 이번 프로젝트에서만 입력을 f1에서만 받는다고 가정 나중에 다시 처리하기
        		text.add("F1");
        		lineAddrs.add(addr++);
        		text_secs.add(h_flag);
        		temp = line.substring(idx+2, idx + 8).trim();
        		text.add(temp);
        		lineAddrs.add(addr);
        		text_secs.add(h_flag);
        		addr+=3;
        		break;
        	}
        	text_secs.add(h_flag);
            text.add(temp);
        }

        if(idx + 2 == line.length()) {//남은 text 처리
        	text.add(line.substring(idx, idx+2));
        	lineAddrs.add(addr);
    	}
	}
	
	void parseModify(String line) {
		
        int addr      = Integer.parseInt(line.substring(1, 7), 16);
        int length = Integer.parseInt(line.substring(7, 9), 16);
        char sign = line.charAt(9); // + or - (필요하면 따로 보관)
        String sym    = line.substring(10).trim();

        modifyRecords.add(new ModifyRecord(addr, length, sym,sign,h_flag));
	}
	
	/*text modify해주는 함수 */
	void modify_text() {
		
		for(ModifyRecord m : modifyRecords) {
			
			int address_real = rMgr.symtabList.search(m.symbol.trim());
			
			int index = -1;//text list 접근 index 찾기
			
			//수정할 길이별 처리
			if(m.length == 5) {
				index = lineAddrs.indexOf(m.address - 1 + startAddress[m.sec-1]);
			}else if(m.length == 6) {
				index = lineAddrs.indexOf(m.address+ startAddress[m.sec-1]);
			}
			
			if(index == -1) {
				System.out.printf("%x\n",m.address);
				continue;
			}
			
			String oldStr = text.get(index);
			String newStr;//modify string
			
			if(m.length == 5) {
				
				if(m.sign == '+') {
					newStr = Integer.toHexString((Integer.parseInt(oldStr.substring(3),16) + address_real));
				}else {
					newStr = Integer.toHexString((Integer.parseInt(oldStr.substring(3),16) - address_real));
				}
				
				if(newStr.length() == 4){
					text.set(index, (oldStr.substring(0,4)  + newStr));
				}else if(newStr.length() == 3) {
					text.set(index, (oldStr.substring(0,5)  + newStr));
				}
				else if(newStr.length() == 2) {
					text.set(index, (oldStr.substring(0,6)  + newStr));
				}
				
			}else if(m.length == 6) {
				
				if(m.sign == '+') {
					newStr = Integer.toHexString((Integer.parseInt(oldStr,16) + address_real));
				}else {
					newStr = Integer.toHexString((Integer.parseInt(oldStr,16) - address_real));
				}
				
				if(newStr.length() == 4) {
					text.set(index, "00"+newStr);
				}else {
					text.set(index, newStr);
				}
					
			}
			
		}

	}	
	
	/*get 함수들*/
	public String getProgramName() {
		return this.programName;
	}
	public int getStartAddress() {
		return this.startAddress[0];
	}
	public String getProgramLength() {
		return Integer.toHexString(this.whole_length);
	}
	
}

