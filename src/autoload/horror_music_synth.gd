# horror_music_synth.gd
# Procedural horror ambient music generator using AudioStreamGenerator
extends AudioStreamPlayer

var playback: AudioStreamGeneratorPlayback
var mix_rate: float = 22050
var phase: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = &"Master"
	
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = 0.5
	
	stream = generator
	play()
	
	playback = get_stream_playback()

func _process(_delta: float) -> void:
	if not playback:
		return
		
	var to_fill := playback.get_frames_available()
	while to_fill > 0:
		var t := phase / mix_rate
		
		# Base ominous drone (low detuned sine waves)
		var base_freq1 := 48.0 + sin(2.0 * PI * 0.05 * t) * 1.0  # Slow detuning around 48Hz (G0)
		var base_freq2 := 48.3 + cos(2.0 * PI * 0.04 * t) * 0.8  # Detuned second harmonic
		
		var osc1 := sin(2.0 * PI * base_freq1 * t) * 0.35
		var osc2 := sin(2.0 * PI * base_freq2 * t) * 0.35
		
		# Low rumbly sub-drone (32Hz)
		var sub := sin(2.0 * PI * 32.0 * t) * 0.2
		
		var sample := osc1 + osc2 + sub
		
		# Creepy occasional mechanical metallic friction (using high frequency swept ring mod)
		var modifier := sin(2.0 * PI * 0.02 * t) # slow cycle
		if modifier > 0.7:
			var ring_freq := 600.0 + sin(2.0 * PI * 8.0 * t) * 150.0
			var metallic := sin(2.0 * PI * ring_freq * t) * 0.035 * (modifier - 0.7)
			sample += metallic
			
		sample = clamp(sample, -1.0, 1.0)
		
		playback.push_frame(Vector2(sample, sample))
		phase += 1.0
		to_fill -= 1
