import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

typedef void OnError(Exception exception);

void main() {
  runApp(MaterialApp(home: Scaffold(body: AudioApp())));
}

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  @override
  _AudioAppState createState() => _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;

  AudioPlayer audioPlayer;

  String localFilePath;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;
  bool isLoop = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
    _loadFile();
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer();
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
          if (s == AudioPlayerState.PLAYING) {
            setState(() => duration = audioPlayer.duration);
          } else if (s == AudioPlayerState.STOPPED) {
            setState(() {
              position = duration;
            });
          } else if (s == AudioPlayerState.COMPLETED) {
            onComplete();
          }
        }, onError: (msg) {
          setState(() {
            playerState = PlayerState.stopped;
            duration = Duration(seconds: 0);
            position = Duration(seconds: 0);
          });
        });
  }

  Future play() async {
    await audioPlayer.play(localFilePath, isLocal: true);
    setState(() => playerState = PlayerState.playing);
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = Duration();
    });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    setState(() {
      isMuted = muted;
    });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);

    if (isLoop) {
      play();
    }
  }

  //write to app path
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future _loadFile() async {
    final dir = await getApplicationDocumentsDirectory();
    var bytes = await rootBundle.load("assets/audios/TiengMuaRoiDeNgu.mp3");
    final file = File('${dir.path}/audio.mp3');

    writeToFile(bytes,file.path);

    if (await file.exists())
      setState(() {
        localFilePath = file.path;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(child: _buildPlayer()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Visibility(
                      visible: localFilePath == null,
                      child: IconButton(
                        onPressed: () => _loadFile(),
                        iconSize: 128.0,
                        icon: Icon(Icons.cached),
                        color: Colors.cyan,
                      )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() => Container(
    padding: EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Visibility(
          visible: localFilePath != null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              onPressed: isPlaying ? null : () => play(),
              iconSize: 128.0,
              icon: Icon(Icons.play_arrow),
              color: Colors.cyan,
            ),
            IconButton(
              onPressed: isPlaying || isPaused ? () => stop() : null,
              iconSize: 128.0,
              icon: Icon(Icons.stop),
              color: Colors.cyan,
            ),
          ]),
        ),
        if (duration != null)
          Slider(
              value: position?.inMilliseconds?.toDouble() ?? 0.0,
              onChanged: (double value) {
                return audioPlayer.seek((value / 1000).roundToDouble());
              },
              min: 0.0,
              max: duration.inMilliseconds.toDouble()),
//        if (position != null) _buildMuteButtons(),
        if (position != null) _buildLoopButtons(),
        if (position != null) _buildProgressView()
      ],
    ),
  );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
    Padding(
      padding: EdgeInsets.all(12.0),
      child: CircularProgressIndicator(
        value: position != null && position.inMilliseconds > 0
            ? (position?.inMilliseconds?.toDouble() ?? 0.0) /
            (duration?.inMilliseconds?.toDouble() ?? 0.0)
            : 0.0,
        valueColor: AlwaysStoppedAnimation(Colors.cyan),
        backgroundColor: Colors.grey.shade400,
      ),
    ),
    Text(
      position != null
          ? "${positionText ?? ''} / ${durationText ?? ''}"
          : duration != null ? durationText : '',
      style: TextStyle(fontSize: 24.0),
    )
  ]);

  Row _buildMuteButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        if (!isMuted)
          FlatButton.icon(
            onPressed: () => mute(true),
            icon: Icon(
              Icons.headset_off,
              color: Colors.cyan,
            ),
            label: Text('Mute', style: TextStyle(color: Colors.cyan)),
          ),
        if (isMuted)
          FlatButton.icon(
            onPressed: () => mute(false),
            icon: Icon(Icons.headset, color: Colors.cyan),
            label: Text('Unmute', style: TextStyle(color: Colors.cyan)),
          ),
      ],
    );
  }

  Row _buildLoopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        if (!isLoop)
          FlatButton.icon(
            onPressed: () => setState(() => isLoop = true),
            icon: Icon(Icons.repeat, color: Colors.grey, size: 32.0),
            label: Text('No Repeat', style: TextStyle(color: Colors.grey)),
          ),
        if (isLoop)
          FlatButton.icon(
            onPressed: () => setState(() => isLoop = false),
            icon: Icon(Icons.repeat_one, color: Colors.cyan, size: 32.0),
            label: Text('Repeat', style: TextStyle(color: Colors.cyan)),
          ),
      ],
    );
  }
}