import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum PlayerState { stopped, playing, paused }

class AudioPlayerContainer extends StatefulWidget {
  @override
  _AudioPlayerContainerState createState() => new _AudioPlayerContainerState();
}

class _AudioPlayerContainerState extends State<AudioPlayerContainer> {
  AudioPlayer advancedPlayer;
  AudioCache audioCache;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;

  bool isLoop = true;

  @override
  void initState(){
    super.initState();
    initPlayer();
  }

  @override
  void dispose() {
    advancedPlayer.stop();
    super.dispose();
  }

  void initPlayer(){
    advancedPlayer = new AudioPlayer();
    advancedPlayer.onPlayerCompletion.listen((event) {
      setState(() {
        playerState = PlayerState.stopped;
      });

      if (isLoop) {
        play();
      }
    });
    advancedPlayer.onPlayerError.listen((msg) {
      setState(() {
        playerState = PlayerState.stopped;
      });
    });

    // play assets audio
    audioCache = new AudioCache(fixedPlayer: advancedPlayer);
  }

  Future play() async {
    await audioCache.play('audios/TiengMuaRoiDeNgu.mp3');
    setState(() => playerState = PlayerState.playing);
  }

  Future stop() async {
    await advancedPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!isPlaying)
                IconButton(
                  onPressed: () => play(),
                  icon: Icon(Icons.play_arrow),
                  iconSize: 230,
                  color: Colors.cyan,
                )
              else
                IconButton(
                  onPressed: () => stop(),
                  icon: Icon(Icons.stop),
                  iconSize: 230,
                  color: Colors.cyan,
                ),

            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => isLoop = !isLoop),
        child: isLoop ? Icon(Icons.repeat_one) : Icon(Icons.repeat),
        backgroundColor: isLoop ? Colors.cyan : Colors.grey,
      )
    );
  }
}