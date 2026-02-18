package Assem;

import java.util.ArrayList;


public class LiteralTable {

    ArrayList<String> literalList;
    ArrayList<Integer> locationList;

    public LiteralTable() {
        literalList  = new ArrayList<>();
        locationList = new ArrayList<>();
    }
    
    //literal table에 literal 추가
    public void putLiteral(String literal) {
    	if (!literalList.contains(literal)) {
            literalList.add(literal);
            locationList.add(null);
        }
    }

    // 필요 메서드 추가 구현
    
    //literal string 입력 받으면 주소값 return
    public int searchLiteral(String literal) {
        int idx = literalList.indexOf(literal);
        if (idx < 0) return -1;
        Integer addr = locationList.get(idx);
        return (addr != null ? addr : -1);
    }

    public int size() {//literal table size 
        return literalList.size();
    }
 
    //literal 값에 맞는 주소값 등록
    public void setLiteralAddress(String literal, int address) {
        int idx = literalList.indexOf(literal);
        if (idx < 0) {
            throw new IllegalArgumentException("Literal not found: " + literal);
        }
        locationList.set(idx, address);
    }
  
    public int getAddress(String literal) {//literal 주소값 return
        int idx = searchLiteral(literal);
        return (idx >= 0) ? locationList.get(idx) : -1;
    }
    
    //file 출력 위해서
    public ArrayList<String> getLiterals() {//모든 리터럴 문자열 목록을 반환한다.
        return new ArrayList<>(literalList);
    }

    public ArrayList<Integer> getAddresses() {//모든 리터럴 주소 목록을 반환한다.
        return new ArrayList<>(locationList);
    }
    
}
