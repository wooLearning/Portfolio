package Assem;

import java.util.ArrayList;

//최종 output code를 위한 class
public class Section {
    public String name;               // H program name
    public int    startAddress;       // H start address
    public int    length;             // H program length

    public ArrayList<Define>      defines;     // D records
    public ArrayList<String>      references;  // R records
    public ArrayList<TextRecord>  textRecords; // T records
    public ArrayList<Modification> modifications; // M records

    public boolean isMain;//첫 섹션이면 true

    public Section() {
    	defines       = new ArrayList<>();
        references    = new ArrayList<>();
        textRecords   = new ArrayList<>();
        modifications = new ArrayList<>();
    }
    
    /* Define 항목을 담는 클래스 */
    public static class Define {
        public String symbol;
        public int    address;
    }

    /* Text 레코드를 담는 클래스 */
    public static class TextRecord {
        public int         startAddress;
        public int         length;        
        public ArrayList<String> objectCodes;  
    }

    /* Modification 레코드를 담는 클래스 */
    public static class Modification {
        public int    address;
        public int    length;
        public String symbol;  
    }
}