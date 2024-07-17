import 'dart:async';

import 'package:client/connection.dart';
import 'package:flutter/material.dart';

void main() async {
  Connection().connect();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final StreamController<String> _isConnected =
      StreamController<String>.broadcast();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Connection().on('connection_status', (String status) {
      _isConnected.add(status);
    });
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<String>(
          stream: _isConnected.stream,
          initialData: 'Connecting',
          builder: (_, snapshot) {
            return MyHomePage(title: "My Chat App ${snapshot.data}");
          }),
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
  final TextEditingController _sessionId = TextEditingController();

  final TextEditingController _perSessionId = TextEditingController();

  final TextEditingController _newMessage = TextEditingController();

  final StreamController<List<Map<String, dynamic>>> _streamMessages =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _currentMessages = [];

  @override
  void initState() {
    super.initState();
    Connection().on('connected', (Map<String, dynamic> payload) {
      _sessionId.text = payload['session_id'];
    });
    Connection().on('message', addMessage);
  }

  void _showDialog() {
    final TextEditingController textFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Group id like Group_1'),
          content: TextField(
            controller: textFieldController,
            decoration: const InputDecoration(
                hintText: "Type your Group id"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Join'),
              onPressed: () {
                Connection().joinRoom(
                  roomId: textFieldController.text
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s+'), '_'),
                );
                _perSessionId.text = textFieldController.text;
                _currentMessages.clear();
                _streamMessages.add(_currentMessages);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _showDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _streamMessages.stream,
          initialData: const [],
          builder: (context, snapshot) {
            List<Map<String, dynamic>> incomingMessages = snapshot.data ?? [];
            return SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              TextField(
                                controller: _sessionId,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  label: Text(
                                      'My Session Id (Copy this id and send to your friend)'),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              TextField(
                                controller: _perSessionId,
                                decoration: const InputDecoration(
                                  label: Text(
                                      'My Friend Session Or room Id (Pasts your friend Or room  id)'),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: incomingMessages.isEmpty
                              ? const Center(
                                  child: Text('Send new Message'),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  itemCount: incomingMessages.length,
                                  itemBuilder: (context, index) {
                                    bool isMe = incomingMessages[index]['sender_id'] == _sessionId.text;
                                    return Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: isMe
                                              ? Colors.green
                                              : Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              blurRadius: 1,
                                              color: Colors.black,
                                              offset: Offset(0.1, 0.1),
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              incomingMessages[index]
                                                  ['message'],
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 9,
                                child: TextField(
                                  controller: _newMessage,
                                  decoration: const InputDecoration(
                                    label: Text('Type your message'),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  String msg = _newMessage.text;
                                  Connection().send(event: 'message', payload: {
                                    'to_session_id': _perSessionId.text,
                                    'message': msg
                                  });
                                  _newMessage.clear();
                                },
                                icon: const Icon(
                                  Icons.send,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  void addMessage(Map<String, dynamic> newMessage) {
    _currentMessages.add(newMessage);
    _streamMessages.add(_currentMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
}
