# audio_synth.gd
# Procedural synthesizer for instant audio effects in Godot
class_name AudioSynth
extends Node

static func play_flashlight_click(node: Node) -> void:
	var player := AudioStreamPlayer.new()
	node.add_child(player)
	
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.1
	
	player.stream = generator
	player.play()
	
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback:
		# Generate a 40ms high-pitch mechanical toggle click
		var sample_rate: float = 22050.0
		var duration: float = 0.04
		var frames := int(sample_rate * duration)
		
		for i in range(frames):
			var t := float(i) / sample_rate
			# High-pass click sound (rapid decay)
			var osc := sin(2.0 * PI * 1500.0 * t) * exp(-120.0 * t)
			# Add a tiny bit of white noise decay for mechanical texture
			var noise := (randf() * 2.0 - 1.0) * 0.15 * exp(-200.0 * t)
			var sample := osc + noise
			playback.push_frame(Vector2(sample, sample))
			
	# Automatically clean up when done
	await player.finished
	player.queue_free()
