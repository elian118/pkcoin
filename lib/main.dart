import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:pkcoin/slider_widget.dart';
import 'package:pkcoin/widgets/buttons.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

Future main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: const MyHomePage(title: 'QTF'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;
  bool data = false;
  int myAmount = 0;
  // 메타마스크 계정 주소
  final myAddress = dotenv.env['METAMASK_ADDRESS'];
  // 리믹스 IDE -> Deployed Contracts 바로 밑에 있는 해시코드 복붙
  //  -> 이 해시코드는 솔리디티 코드가 배포 완료된 이후에 확인 가능하다.
  final contractAddr = dotenv.env['CONTRACT_ADDRESS'];
  final infuraKey = dotenv.env['INFURA_API_KEY'];
  final myPrivateKey = dotenv.env['METAMASK_PRIVATE_KEY'];

  String txHash = '';
  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    // 원래는 메인넷으로 서비스해야 하나, 테스트넷 설정은 살짝 바꿔줘야 한다.
    // 인퓨라 -> 연결된 프로젝트 엔드포인트 -> 이더리움 -> 'gorli 테스트넷'으로 지정 후 뜬 주소를 여기 입력
    ethClient = Web3Client(
      'https://goerli.infura.io/v3/$infuraKey',
      httpClient,
    );
    getBalance(myAddress!);
  }

  // JSON 형식으로 컴파일된 스마트컨트렉트 코드 불러오기
  Future<DeployedContract> loadContract() async {
    // 리믹스 IDE -> 솔리디티 컴파일러 -> Compilation Details 버튼 오른쪽 밑 -> ABI 클릭(JSON 형식으로 코드 복사)
    //  -> 프로젝트에 assets/abi.json 경로 및 파일 생성하고 코드 복붙
    String abi = await rootBundle.loadString("assets/abi.json");

    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoin"),
        EthereumAddress.fromHex(contractAddr!));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
      contract: contract,
      function: ethFunction,
      params: args,
    );

    return result;
  }

  // 잔고 조회 -> 가상화폐는 아니고, 단순 state 조회
  Future<void> getBalance(String targetAddress) async {
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];
    data = true;
    print('Refreshed');
    setState(() {});
  }

  // 제출 -> 잔고 조회(갱신), 입금, 인출
  Future<String> submit(String functionName, List<dynamic> args) async {
    // 테스트를 위해 메타마스크로부터 계정 비공개 키를 하드코드로 입력. api 안 씀
    EthPrivateKey credentials = EthPrivateKey.fromHex(myPrivateKey!);

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: ethFunction,
          parameters: args,
        ),
        chainId: null,
        fetchChainIdFromNetworkId: true);
    return result;
  }

  // 입금
  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmount]);

    print("Deposited");
    txHash = response;
    setState(() {});
    return response;
  }

  // 인출
  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmount]);

    print("Withdrawn");
    txHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight * 30)
            .make(),
        VStack([
          (context.percentHeight * 10).heightBox,
          "\$QTF".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight * 5).heightBox,
          VxBox(
            child: VStack([
              10.heightBox,
              "잔고".text.gray700.xl2.semiBold.makeCentered(),
              10.heightBox,
              data
                  ? "\$$myData".text.bold.xl6.makeCentered().shimmer()
                  : const CircularProgressIndicator().centered(),
            ]),
          )
              .white
              .size(context.screenWidth, context.percentHeight * 18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,
          SliderWidget(
            min: 0,
            max: 100,
            value: myAmount.toDouble(),
            onChangeValue: (value) {
              myAmount = (value).round();
              setState(() {});
            },
          ),
          Buttons(
            getBalance: getBalance,
            myAddress: myAddress!,
            sendCoin: sendCoin,
            withdrawCoin: withdrawCoin,
          ),
          if (txHash.isNotEmpty) txHash.text.black.makeCentered().p16(),
        ])
      ]),
    );
  }
}
