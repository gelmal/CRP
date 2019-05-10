let provider = require("../api/provider.js"); // eth.accounts 얻어오기 위함
let act = require("../api/api_action.js");
let api_main = require("../api/api_main.js");

/**
 * Usage 출력 함수이다.
 * 
 * @author sykang
 */
function Usage() {
    console.log("Usage --> ");
    console.log("    node TestMainAddRoadmapPollAddress.js [argv1] [argv2] [argv3] [argv4]");
    console.log("....argv1: Owner 계정 (Index)");
    console.log("....argv2: Owner 암호");
    console.log("....argv3: 메인 컨트랙트 주소");
    console.log("....argv4: 등록할 로드맵 폴 주소");
}

/**
 * 진행상황 출력 함수이다.
 * 
 * @param _result 성공 / 실패
 * @param _count 시도 횟수
 * @author jhhong
 */
function showProgress(_result, _count) {
    if(_result == true) {
        console.log("[" + _count + "]th trying...Success!");
    } else {
        console.log("[" + _count + "]th trying...Failed!");
    }
}

/**
 * 화면을 클리어한다.
 * 
 * @author jhhong
 */
function ClearScreen() {
    console.clear();
    console.log(".");
    console.log(".");
    console.log(".");
} 

/**
 * 프로시져 수행 메인 함수이다. 
 * 
 * @author sykang4966
 */
let RunProc = async () => {
    try {
        ClearScreen();
        if(process.argv.length != 6) {
            Usage();
            throw new Error("Invalid Argument!");
        }
        /* 파라메터 체크 */
        console.log('* Param01 (Owner Account Index):....' + process.argv[2]);
        console.log('* Param02 (Owner Password):.........' + process.argv[3]);
        console.log('* Param03 (CrpMain Address):........' + process.argv[4]);
        console.log('* Param04 (CrpPollRoadmap Address):....' + process.argv[5]);
        const owner = provider.web3.eth.accounts[process.argv[2]]; // owner account 주소
        const passwd = process.argv[3]; // owner 비번
        const mainaddr = process.argv[4]; // 메인 컨트랙트 주소
        const roadaddr = process.argv[5]; // 크라우드세일 컨트랙트 주소
        console.log('Owner Account: [' + owner + ']');
        if(await act.tryActions(api_main.addRoadmapPollAddress, showProgress, false, 5, true, owner, passwd, mainaddr, roadaddr) == false) {
            throw new Error("Failed! (addRoadmapPollAddress)");
        }
        let mainobj = await api_main.getObject(mainaddr);
        let idx = mainobj.getRoadmapContractNum() - 1;
        console.log("### 등록된 로드맵폴 인덱스 ==> [" + idx + "]");
        console.log("    등록된 로드맵폴 주소 ==> [" + mainobj.roadmap_addrs(idx) + "]");
    } catch(err) {
        console.log(err);
    }
}
RunProc();