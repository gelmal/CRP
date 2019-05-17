pragma solidity ^ 0.4 .24;

import "./SafeMath.sol";
import "./CrpInfc.sol";

/// @title the AddSale Poll contract (version 0.1)
/// @author sykang
contract CrpPollAdSale is CrpInfc {
    using SafeMath
    for uint256;

    // struct : 계정 별 투표 목록 관리
    struct Vote {
        uint256 time; // 투표 시간
        uint256 weight; // 투표 양
        bool agree; // 찬반 여부
        address prev; // 전 투표자
        address next; // 후 투표자
    }

    //struct : 추가 크라우드 세일 데이터 목록 관리
    struct SaleInfo {
        uint256 start; // 시작시간
        uint256 end; // 종료시간
        uint256 mid; // 중간시간
        uint256 min; // 최소금액
        uint256 max; // 최대금액
        uint256 hardcap; // 모금 한계치
        uint256 rate; // 토큰 교환비율
    }

    // public variable        
    uint256 public agree_addr; // 실시간 찬성 계좌
    uint256 public disagree_addr; // 신시간 반대 계좌

    uint256 public total_addr; // 정산 후 홀더 총 계좌 수
    uint256 public total_agree; // 정산 후 찬성 표
    uint256 public total_weight; // 정산 후 투표 량

    uint256 public poll_started; // 투표 시작 시간
    uint256 public poll_ended; // 투표 종료 시간

    bool public result_poll; // 투표 결과 
    bool public settle;  // statement settle variable
    uint public voter_count; // 투표자 수
  

    address public main_contract; // 메인컨트렉트 주소
    address public owner; // 오너 계좌
    address public head; // 투표자 주소 체인 머리
    address public last; // 투표자 주소 체인 꼬리
    
    SaleInfo public sale_info; // 투표자 투표 정보를 저장

    // private variable
    string constant contract_type = "POLLADSALE";

    // mapping
    mapping(address => Vote) vote_info; //투표 정보 맵핑

    // modifier
    modifier isProjectOwner(address _address) { // 토큰 owner인지 검사
        require(_address == owner);
        _;
    }

    /// @author sykang
    /// @notice the constructor of CrpPollAdsale contract    
    /// @param _poll_start_time poll start time this contract
    /// @param _poll_end_time poll end time this contract
    /// @param _sale_start_time sale start time after deploy adsale contract
    /// @param _sale_end_time sale end time after deploy adsale contract
    /// @param _sale_mid_time sale mid time after deploy adslae contract
    /// @param _min minimum transfer crp amount to after deploy adsale contract
    /// @param _max maximum trqnsfer crp amount to after deploy adsale contract
    /// @param _hardcap maximum sale amount to sailing
    /// @param _rate exchange rate Crp to token    
    /// @param _main the address of CrpToken contract
    constructor(uint256 _poll_start_time, uint256 _poll_end_time, uint256 _sale_start_time, uint256 _sale_end_time, uint256 _sale_mid_time, uint256 _min, uint256 _max, uint256 _hardcap, uint256 _rate, address _main)
    public {
        poll_started = _poll_start_time;
        poll_ended = _poll_end_time;
        sale_info.start = _sale_start_time;
        sale_info.end = _sale_end_time;
        sale_info.mid = _sale_mid_time;
        sale_info.min = _min;
        sale_info.max = _max;        
        sale_info.hardcap = _hardcap;
        sale_info.rate = _rate;
        main_contract = _main;
        owner = msg.sender;
        result_poll = true;
        settle = false;
        voter_count = 0;
    }

    /// @author sykang
    /// @notice interface, return contract type
    /// @return const variable of contract_type
    function getContractType()
    public view
    returns(string) {
        return contract_type;
    }

    /// @author sykang
    /// @notice return vote_info element by _addr
    /// @param _addr check _addr
    /// @return vote_info element
    function getVoteInfo(address _addr)
    public view
    returns(uint256, uint256, bool, address, address) {
        return (vote_info[_addr].time, vote_info[_addr].weight, vote_info[_addr].agree, vote_info[_addr].prev, vote_info[_addr].next);
    }

    /// @author sykang
    /// @notice polling by attended crowdSale
    /// @param _vote Votes of voters  (bool)
    function polling(uint256 _vote) external {
        //require(now>poll_started && now<poll_ended);
        require(vote_info[msg.sender].time == 0);
        //개표
        if (_vote == 0) { // disagree
            vote_info[msg.sender].agree = false;
            disagree_addr = disagree_addr.add(1);
        } else if (_vote == 1) { //agree
            vote_info[msg.sender].agree = true;
            agree_addr = agree_addr.add(1);
        }
        // 체인 작업
        if (head == address(0)) { // 첫 투표자
            head = last = msg.sender;
        } else {
            vote_info[last].next = msg.sender;
            vote_info[msg.sender].prev = last;
            last = msg.sender;
        }
        voter_count=voter_count.add(1);
        vote_info[msg.sender].time = now;
    }

    /// @author sykang
    /// @notice cancel polled record by attended crowdSale
    function cancelPoll()
    external {
        require(vote_info[msg.sender].time != 0);
        //require(now>poll_started && now<poll_ended);  

        bool voted = vote_info[msg.sender].agree;
        if (voted) {
            agree_addr = agree_addr.sub(1);
        } else {
            disagree_addr = disagree_addr.sub(1);
        }
        voter_count=voter_count.sub(1);
        vote_info[msg.sender].time = 0;
    }

    /// @author sykang
    /// @notice set address to token weight
    /// @param _addr Account to be allocated token weight
    /// @param _amount token weight at _addr
    function setAmount(address _addr, uint256 _amount)
    external {
        vote_info[_addr].weight = _amount;
    }

    /// @author sykang
    /// @notice Settle the results of a vote
    /// @param _addr_count total token account
    /// @param _total_token total token amount
    /// @param _total_agree total agree token
    function settlePoll(uint256 _addr_count, uint256 _total_token, uint256 _total_agree)
    isProjectOwner(msg.sender)
    external {
        //require(now > poll_ended);
        total_addr = _addr_count;
        total_weight = _total_token;
        total_agree = _total_agree;
        settle = true;

        uint256 tmp = (total_addr.mul(7)).div(10); // 70% 계좌수
        uint256 tmp_total = agree_addr.add(disagree_addr); //  전체 투표자 수

        if (tmp > tmp_total) { // 투표율이 70% 이하
            result_poll = false;
        } else {
            tmp_total = (tmp_total.mul(7)).div(10); // 전체 투표자 수에 70%
            if (tmp_total > agree_addr) { // 찬성 투표자 수가 전체 투표자 수의 70%이하
                result_poll = false;
            } else {
                uint256 tmp_poll = (total_weight.mul(7)).div(10); // 전체 투표에 참가한 토큰 수의 70%
                if (tmp_poll > total_agree) { // 찬성 보유량이 70% 이하
                    result_poll = false;
                }
            }
        }
    }
}