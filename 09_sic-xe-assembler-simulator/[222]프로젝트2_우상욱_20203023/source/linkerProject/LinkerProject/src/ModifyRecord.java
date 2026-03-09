public class ModifyRecord {
	  public final int    address, length;
	  public final String symbol;
	  public char sign;
	  public int sec;
	  
	  public ModifyRecord(int address,int length,String symbol, char sign, int sec){
	    this.address=address; this.length =length; this.symbol=symbol; this.sign = sign;
	    this.sec = sec;
	  }
	  public void modi_print() {
		  System.out.println(address + " " + length + " "+symbol+" " +sign+ " "+sec );
	  }  
}