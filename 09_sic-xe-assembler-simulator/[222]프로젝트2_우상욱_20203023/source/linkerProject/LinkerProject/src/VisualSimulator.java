import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.awt.event.*;
import java.io.File;

/**
 * VisualSimulator는 사용자와의 상호작용을 담당한다. 즉, 버튼 클릭등의 이벤트를 전달하고 그에 따른 결과값을 화면에 업데이트
 * 하는 역할을 수행한다.
 * 
 * 실제적인 작업은 SicSimulator에서 수행하도록 구현한다.
 */
public class VisualSimulator extends JFrame {
    ResourceManager rMgr = new ResourceManager();
    //SicLoader       sicLoader       = new SicLoader(resourceManager);
    SicSimulator    sicSimulator    = new SicSimulator(rMgr);

    // --- UI components ---
    private JTextField txtFileName  = new JTextField(20);
    private JButton    btnOpen      = new JButton("open");

    private JTextField txtHName     = new JTextField(12);
    private JTextField txtHStart    = new JTextField(12);
    private JTextField txtHLength   = new JTextField(12);

    private JTextField txtEFirst    = new JTextField(12);
    private JTextField txtEStartMem = new JTextField(12);

    private String[]     basicNames  = {"A (#0)","X (#1)","L (#2)","PC (#8)","SW (#9)"};
    private JTextField[] regBasicDec = new JTextField[basicNames.length];
    private JTextField[] regBasicHex = new JTextField[basicNames.length];

    private String[]     xeNames     = {"B (#3)","S (#4)","T (#5)","F (#6)"};
    private JTextField[] regXEDec    = new JTextField[xeNames.length];
    private JTextField[] regXEHex    = new JTextField[xeNames.length];

    private JTextField           txtTarget = new JTextField(12);
    private DefaultListModel<String> instModel = new DefaultListModel<>();
    private JList<String>        lstInst   = new JList<>(instModel);

    private JTextField txtDevice    = new JTextField(12);
    private JButton    btnStep1     = new JButton("실행(1step)");
    private JButton    btnRunAll    = new JButton("실행(all)");
    private JButton    btnExit      = new JButton("종료");

    private JTextArea  txtLog       = new JTextArea(6, 60);

    public VisualSimulator() {
        super("SIC/XE Simulator");
        setDefaultCloseOperation(EXIT_ON_CLOSE);

        // --- Top: File chooser panel ---
        JPanel filePanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));
        filePanel.add(new JLabel("FileName :"));
        txtFileName.setEditable(false);
        filePanel.add(txtFileName);
        filePanel.add(btnOpen);
        add(filePanel, BorderLayout.NORTH);

        // --- Left column: H record & registers ---
        JPanel leftColumn = new JPanel();
        leftColumn.setLayout(new BoxLayout(leftColumn, BoxLayout.Y_AXIS));
        leftColumn.add(createHPanel());
        leftColumn.add(Box.createVerticalStrut(8));
        leftColumn.add(createBasicRegPanel());
        leftColumn.add(Box.createVerticalStrut(8));
        leftColumn.add(createXERegPanel());

        // --- Right column: E record & instructions/controls ---
        JPanel rightColumn = new JPanel();
        rightColumn.setLayout(new BoxLayout(rightColumn, BoxLayout.Y_AXIS));

        // E 패널 (위)
        rightColumn.add(createEPanel());
        rightColumn.add(Box.createVerticalStrut(10));

        // Instructions+Controls (아래)
        JPanel instCtrl = new JPanel(new BorderLayout(8,8));
        instCtrl.add(createInstPanel(),    BorderLayout.CENTER);
        instCtrl.add(createControlPanel(), BorderLayout.EAST);
        rightColumn.add(instCtrl);

        // 그리고 center 영역에 leftColumn 과 함께 붙이세요
        JPanel center = new JPanel(new GridLayout(1,2,10,10));
        center.add(leftColumn);
        center.add(rightColumn);
        add(center, BorderLayout.CENTER);

        // --- Bottom: Log panel ---
        JPanel logPanel = new JPanel(new BorderLayout());
        logPanel.setBorder(new TitledBorder("Log (명령어 수행 관련):"));
        txtLog.setEditable(false);
        logPanel.add(new JScrollPane(txtLog), BorderLayout.CENTER);
        add(logPanel, BorderLayout.SOUTH);

        // --- Finalize window ---
        pack();
        setLocationRelativeTo(null);
        setVisible(true);
        
        // --- Event handlers ---
        
        btnOpen.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
                File f = chooser.getSelectedFile();
                txtFileName.setText(f.getName());
                load(f);
            }
        });
        
        
      //for debug
        /*
        File debugFile = new File("output_objectcode.txt");
        if (debugFile.exists()) {
            txtFileName.setText(debugFile.getName());
            load(debugFile);
        }
        */
        
        
        btnStep1.addActionListener(e -> { oneStep(); });
        btnRunAll.addActionListener(e -> { allStep(); });
        btnExit.addActionListener(e -> dispose());
        
        
    }

    private JPanel createHPanel() {
        JPanel p = new JPanel(new GridBagLayout());
        p.setBorder(new TitledBorder("H (Header Record)"));
        GridBagConstraints c = new GridBagConstraints();
        c.insets = new Insets(2,2,2,2); c.anchor = GridBagConstraints.WEST;

        // Program name
        c.gridx=0; c.gridy=0; p.add(new JLabel("Program name :"), c);
        c.gridx=1; c.fill=GridBagConstraints.HORIZONTAL; c.weightx=1; p.add(txtHName, c);
        // Start Address
        c.gridy=1; c.gridx=0; c.fill=GridBagConstraints.NONE; c.weightx=0; p.add(new JLabel("Start Address of Object Program :"), c);
        c.gridx=1; c.fill=GridBagConstraints.HORIZONTAL; c.weightx=1; p.add(txtHStart, c);
        // Length
        c.gridy=2; c.gridx=0; c.fill=GridBagConstraints.NONE; c.weightx=0; p.add(new JLabel("Length of Program :"), c);
        c.gridx=1; c.fill=GridBagConstraints.HORIZONTAL; c.weightx=1; p.add(txtHLength, c);

        return p;
    }

    private JPanel createEPanel() {
        JPanel p = new JPanel(new GridBagLayout());
        p.setBorder(BorderFactory.createTitledBorder("E (End Record)"));

        GridBagConstraints c = new GridBagConstraints();
        c.insets = new Insets(2,2,2,2);
        c.anchor = GridBagConstraints.WEST;

        // 1행: Address of First Instruction
        c.gridx = 0; c.gridy = 0;
        p.add(new JLabel("Address of First instruction in Object Program :"), c);
        c.gridx = 1; c.fill = GridBagConstraints.HORIZONTAL; c.weightx = 1;
        p.add(txtEFirst, c);

        // 2행: Start Address in Memory
        c.gridx = 0; c.gridy = 1; c.fill = GridBagConstraints.NONE; c.weightx = 0;
        p.add(new JLabel("Start Address in Memory :"), c);
        c.gridx = 1; c.fill = GridBagConstraints.HORIZONTAL; c.weightx = 1;
        p.add(txtEStartMem, c);
        Dimension pref = p.getPreferredSize();
        p.setMaximumSize(new Dimension(pref.width, pref.height));
        return p;
    }

    private JPanel createBasicRegPanel() {
        JPanel p = new JPanel(new GridLayout(basicNames.length+1,3,4,4));
        p.setBorder(new TitledBorder("Register"));
        p.add(new JLabel("")); p.add(new JLabel("Dec")); p.add(new JLabel("Hex"));
        for (int i = 0; i < basicNames.length; i++) {
            p.add(new JLabel(basicNames[i]));
            regBasicDec[i] = new JTextField(6); regBasicDec[i].setEditable(false); p.add(regBasicDec[i]);
            regBasicHex[i] = new JTextField(6); regBasicHex[i].setEditable(false); p.add(regBasicHex[i]);
        }
        return p;
    }

    private JPanel createXERegPanel() {
        JPanel p = new JPanel(new GridLayout(xeNames.length+1,3,4,4));
        p.setBorder(new TitledBorder("Register (for XE)"));
        p.add(new JLabel("")); p.add(new JLabel("Dec")); p.add(new JLabel("Hex"));
        for (int i = 0; i < xeNames.length; i++) {
            p.add(new JLabel(xeNames[i]));
            regXEDec[i] = new JTextField(6); regXEDec[i].setEditable(false); p.add(regXEDec[i]);
            regXEHex[i] = new JTextField(6); regXEHex[i].setEditable(false); p.add(regXEHex[i]);
        }
        return p;
    }

    private JPanel createInstPanel() {
        JPanel p = new JPanel(new BorderLayout(4,4));
        p.setBorder(new TitledBorder("Instructions"));
        JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT,4,2));
        top.add(new JLabel("Target Address :")); top.add(txtTarget);
        p.add(top, BorderLayout.NORTH);
        p.add(new JScrollPane(lstInst), BorderLayout.CENTER);
        return p;
    }

    private JPanel createControlPanel() {
        JPanel p = new JPanel(new GridLayout(5,1,6,6));
        p.add(new JLabel("사용중인 장치 :")); txtDevice.setEditable(false); p.add(txtDevice);
        p.add(btnStep1); p.add(btnRunAll); p.add(btnExit);
        btnStep1.setEnabled(false); btnRunAll.setEnabled(false);
        return p;
    }

    /**
     * 프로그램 로드 명령을 전달한다.
     */
    public void load(File program) {
        rMgr.initializeResource();

        sicSimulator.load(program);
        instModel.clear();

        btnStep1.setEnabled(true);
        btnRunAll.setEnabled(true);
        
        //header
        txtHName.setText( sicSimulator.loader.getProgramName() );
        txtHStart.setText( Integer.toHexString(sicSimulator.loader.getStartAddress()) );
        txtHLength.setText( sicSimulator.loader.getProgramLength() );
        
        //end box
        txtEStartMem.setText(Integer.toHexString(sicSimulator.loader.getStartAddress()));
        txtEFirst.setText(Integer.toHexString(sicSimulator.loader.getStartAddress()));
        
        oneStep();
        
    }

    /**
     * 하나의 명령어만 수행할 것을 SicSimulator에 요청한다.
     */
    public void oneStep() { 
    	sicSimulator.oneStep();
    	update();//미리 pc값 업데이트 및 실행
    }

    /**
     * 남아있는 모든 명령어를 수행할 것을 SicSimulator에 요청한다.
     */
    public void allStep() {
        Timer t = new Timer(10, null);//timer를 통해 10ms 단위로 명령어 실행과정 및 gui 업데이트
	    t.addActionListener(ev -> {
            if(rMgr.getRegister(8) == 0) {
            	t.stop();
            }else {
            	oneStep();
            }
	       
	    });
	    t.setInitialDelay(0);
	    t.start();
    }

    /**
     * 화면을 최신값으로 갱신하는 역할을 수행한다.
     */
    public void update() {
        // register & log 업데이트 로직
    	instModel.addElement(sicSimulator.inst_field);
    	lstInst.ensureIndexIsVisible(instModel.getSize() - 1);

    	//target address 
    	txtTarget.setText(Integer.toHexString(sicSimulator.target_address));
    	
    	for (int i = 0; i < basicNames.length; i++) {
            int regIdx = switch(i) {
                case 0 -> 0;   // A
                case 1 -> 1;   // X
                case 2 -> 2;   // L
                case 3 -> 8;   // PC
                case 4 -> 9;   // SW
                default -> 0;
            };
            int dec = rMgr.getRegister(regIdx);
            regBasicDec[i].setText(String.valueOf(dec));
            regBasicHex[i].setText(String.format("%06X", dec));
           
        }
        // XE 레지스터(B,S,T,F)
        for (int i = 0; i < xeNames.length; i++) {
            int regIdx = switch(i) {
                case 0 -> 3;  // B
                case 1 -> 4;  // S
                case 2 -> 5;  // T
                case 3 -> 6;  // F
                default -> 0;
            };
            int dec = rMgr.getRegister(regIdx);
            regXEDec[i].setText(String.valueOf(dec));
            regXEHex[i].setText(String.format("%06X", dec));
        }
        txtLog.append(sicSimulator.logs.get(0));
        txtLog.append("\n");
        sicSimulator.logs.clear();
    }

    public static void main(String[] args) {
    	EventQueue.invokeLater(VisualSimulator::new);
    }
}
