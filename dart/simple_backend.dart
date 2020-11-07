import 'dart:io';

class SimpleBackend {
  String address;
  int port;

  ServerSocket _serverSocket = null;
  Socket _clientSocket = null;

  SimpleBackend(this.address, this.port);
  SimpleBackend.localhost() {
    address = "localhost";
    port = 34568;
  }

  void init() async {
    print("SimpleBackend init begin");
    if (_serverSocket == null) {
      _serverSocket = await ServerSocket.bind(address, port);
      _serverSocket.listen(handleIncomingSockets);
    }
    print("SimpleBackend init end");
  }

  void done() {
    _disconnectClient();
    _serverSocket.close();
    _serverSocket = null;
  }

  void handleIncomingSockets(Socket incomingSocket) {
    print("SimpleBackend incoming connection");
    _clientSocket = incomingSocket;
    _clientSocket.listen((event) {
      String msg = String.fromCharCodes(event).trim();
      print('SimpleBackend onData: $msg');
      _clientSocket.write("<- SimpleBackend replying\n");
    }, onError: (error, StackTrace trace) {
      print('SimpleBackend onError: $error trace: $trace');
    }, onDone: () {
      print('SimpleBackend onDone');
    });
  }

  void _disconnectClient() {
    if (_clientSocket != null) {
      _clientSocket.close();
      _clientSocket.destroy();
    }
    _clientSocket = null;
  }
}

Future<void> main(List<String> args) async {
  SimpleBackend backend = new SimpleBackend.localhost();
  await backend.init();

  print("Client connecting backend");
  Socket client = await Socket.connect(backend.address, backend.port);

  int repliesCount = 0;

  client.listen((event) {
    String msg = String.fromCharCodes(event).trim();
    print('Client onData: $msg');
    repliesCount++;
    if (repliesCount > 10) {
      client.close();
      backend.done();
    } else {
      client.write("-> Client says HELLO $repliesCount\n");
    }
  }, onError: (error, StackTrace trace) {
    print('Client onError: $error trace: $trace');
  }, onDone: () {
    print('Client onDone');
  });

  print("Client starts a conversation");
  client.write("-> Client says HELLO\n");
}
