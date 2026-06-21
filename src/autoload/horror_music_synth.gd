# horror_music_synth.gd
# Loads and loops the downloaded Kevin MacLeod horror ambient track
extends AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = &"Master"
	
	# Load downloaded Kevin MacLeod track
	var sfx := load("res://assets/audio/music/horror_ambient.ogg")
	if sfx:
		stream = sfx
		# Configure loop property
		if stream.has_method("set_loop"):
			stream.set_loop(true)
		elif "loop" in stream:
			stream.loop = true
		play()
		print("Playing ambient horror music...")
	else:
		# Procedural fallback synth if file is missing
		_start_fallback_generator()

func play_sfx(path: String) -> void:
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.bus = &"Master"
	add_child(sfx_player)
	var sfx = load(path)
	if sfx:
		sfx_player.stream = sfx
		sfx_player.play()
		await sfx_player.finished
	sfx_player.queue_free()

# --- Fallback Procedural Generator ---
var playback: AudioStreamGeneratorPlayback
var mix_rate: float = 22050
var phase: float = 0.0

func _start_fallback_generator() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = 0.5
	stream = generator
	play()
	playback = get_stream_playback()
	set_process(true)

func _process(_delta: float) -> void:
	if not playback:
		return
		
	var to_fill := playback.get_frames_available()
	while to_fill > 0:
		var t := phase / mix_rate
		var base_freq1 := 48.0 + sin(2.0 * PI * 0.05 * t) * 1.0
		var base_freq2 := 48.3 + cos(2.0 * PI * 0.04 * t) * 0.8
		var osc1 := sin(2.0 * PI * base_freq1 * t) * 0.35
		var osc2 := sin(2.0 * PI * base_freq2 * t) * 0.35
		var sub := sin(2.0 * PI * 32.0 * t) * 0.2
		var sample := osc1 + osc2 + sub
		
		var modifier := sin(2.0 * PI * 0.02 * t)
		if modifier > 0.7:
			var ring_freq := 600.0 + sin(2.0 * PI * 8.0 * t) * 150.0
			sample += sin(2.0 * PI * ring_freq * t) * 0.035 * (modifier - 0.7)
			
		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))
		phase += 1.0
		to_fill -= 1

