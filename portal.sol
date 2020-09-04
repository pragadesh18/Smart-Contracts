pragma solidity ^0.5.0;

import "./BlockXToken.sol";
import "./RewardToken.sol";
import "./program.sol";

contract portal {
    RewardToken public RToken;
    BlockXToken public BToken;
    program public prog;

    mapping(uint => uint) public DonationReceived;
    
     constructor(RewardToken _RToken,BlockXToken _BToken,program _prog) public {
        RToken = _RToken;
        BToken = _BToken;
        prog = _prog;
     }
     
    mapping(address =>mapping(uint => bool)) public ans;
    
    struct validater_details{
        address validater;  
        uint validater_points;
    }
    
    validater_details[] public validater_info;
    
    struct Doner{
        address id;
        string Name;
        uint Amount;
        string Contact_Details;
        string mail_id;
        bool donated;
    }
    
    mapping(address => mapping(uint => Doner)) public doner;
    mapping(address => mapping(uint => uint)) public role;
    mapping(address => bool) public blacklisted;
    mapping(address => mapping(uint => bool)) public isRegistered;
    mapping(address => mapping(uint => address)) public validater;
    
    uint project_count=0;
    
    
    function Program_creation(string memory name, uint Fund_needed, uint duration, string memory descrption,string memory email) public{
        require(!blacklisted[msg.sender], "Not allowed");
        project_count = project_count + 1;
        prog.Program_detail(msg.sender,name,project_count,Fund_needed, duration, descrption,email);
        isRegistered[msg.sender][project_count] = true;
        role[msg.sender][project_count] = 1;
    }
    
    function project_completion_proof(uint program_id,string memory descrption, string memory mail_id, string memory contact_details) public{
       prog.completion_proof(msg.sender,program_id,descrption, mail_id, contact_details);
    }
    
    function Donate(uint program_id,string memory name,string memory email,string memory contact_details, uint amount) public{
        require(!blacklisted[msg.sender], "Not allowed");
        require(amount > 0, "amount cannot be 0");
        uint Fund_needed = prog.Fund_details(program_id);
        uint required = Fund_needed - DonationReceived[program_id];
        if(required<amount){
            amount=required;
        }
        address managerid = prog.Manager_Id(program_id);
        BToken.transferFrom(msg.sender, managerid, amount);
        if(!doner[msg.sender][program_id].donated){
            doner[msg.sender][program_id] = Doner(msg.sender,name,0,contact_details,email,true);
        }
        doner[msg.sender][program_id].Amount = doner[msg.sender][program_id].Amount + amount;
        DonationReceived[program_id] = DonationReceived[program_id] + amount;
        if(amount>250){
            RToken.transfer(msg.sender,10);
        }
        else if(amount>=200){
            RToken.transfer(msg.sender,8);
        }
        else if(amount>=100){
            RToken.transfer(msg.sender,4);
        }
    }
    
    function register_ServiceProvider(string memory name,string memory title,string memory contact_details, string memory email, uint program_id) public{
        require(!blacklisted[msg.sender], "Not allowed");
        require(!isRegistered[msg.sender][program_id],"Already registered");
        prog.ServiceProvider_Info(msg.sender,name,title,contact_details,email,program_id);
        isRegistered[msg.sender][program_id] = true;
        role[msg.sender][program_id] = 2;
    }
    
    function register_Volunteer(string memory name,string memory title,string memory contact_details, string memory email, uint program_id) public {
        require(!blacklisted[msg.sender], "Not allowed");
        require(!isRegistered[msg.sender][program_id],"Already registered");
        prog.Volunteer_info(msg.sender,name,title,contact_details,email,program_id);
        isRegistered[msg.sender][program_id] = true;
        role[msg.sender][program_id] = 3;
    }
    
    function volunteerproof(string memory work_by_volunteer,uint program_id, uint duration, string memory desc,string memory email, string memory contact) public{
        prog.volunteerproof_Info(msg.sender, work_by_volunteer,program_id, duration, desc, email, contact);
    }
    
    function serviceproof(uint program_id,string memory provided_service, string memory descrption, string memory mail_id, string memory contact_details) public{
        prog.serviceproof_info(msg.sender,program_id, provided_service, descrption,mail_id, contact_details);
    }
    
    function validate(address Address,uint id,bool ver) public{
        ans[Address][id]=ver;
        RToken.transfer(validater[Address][id],2);
    }
    
    function check_validater(address Address) public {
        uint i = validater_info.length-1;
        if(i<=0){
            validater_info.push(validater_details({validater:Address,validater_points:RToken.balanceOf(Address)})); 
        }
        else{
            if(validater_info[i].validater_points <= RToken.balanceOf(Address)){
                validater_info.push(validater_details({validater:Address,validater_points:RToken.balanceOf(Address)}));
            }
        }
    }
    
    function select_validater(address Address, uint id) public {
        uint index = validater_info.length-1;
        for(uint i=index;i>=0;i--)
        {
            if(Address != validater_info[i].validater){
                validater[Address][id] = validater_info[i].validater; 
                break;
            }
        }
    }
    
    function verifyproof(address Address,uint id) public {
        uint n = role[Address][id];
        if(n==1){
            if(ans[Address][id]){
               RToken.transfer(Address,5);
            }
            else{
                blacklisted[Address] = true;
            }
        }
        if(n==2){
            if(ans[Address][id]){
                RToken.transfer(Address,3);
            }
            else{
                blacklisted[Address] = true;
            }
        }
        if(n==3){
            if(ans[Address][id]){
                uint duration = prog.get_duration(Address,id);
                uint p = duration * 1;
                RToken.transfer(Address,p);
            }
            else{
                 blacklisted[Address] = true;
            }
        }
    }
}