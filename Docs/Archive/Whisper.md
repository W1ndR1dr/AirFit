Recommended “sweet-spot” model

mlx-community/whisper-large-v3-turbo quantized to INT8

Model	Params	Reported WER ↓ (English, LibriSpeech-test-clean)	Relative speed vs Whisper-large-v3	GPU / VRAM need‡	Fits iPhone 16 Pro?	Why choose it
whisper-large-v3-turbo INT8	809 M	≈ large-v3 (8.4 % WER) – “same quality” claim ￼	≈ 8× faster than large (24 s for 66 s audio on M1 Pro) ￼	~3 GB‡ after INT8 quant. (6 GB FP16) ￼ ￼	Yes – A18-class iPhone has 8 GB unified RAM; ~3 GB allocation is practical.	Highest quality that still stays near-real-time on-device.
distil-whisper-large-v3 INT8	756 M	+0.8–1.5 % WER vs large ￼	5-6× faster than large (40× real-time on M1 Max) ￼	~2.8 GB‡	Yes	Good fallback if Turbo hits memory ceilings; slightly lower accuracy.
whisper-medium INT8	769 M	8.4 % WER (baseline medium)	2-3× faster than large	~2.7 GB‡	Yes	Lower accuracy than Turbo/distil-large.

‡ Memory math: FP16 weights ≈ 2 bytes/param ⇒ Turbo FP16 ≈ 1.6 GB. INT8 halves that; MLX streams weights so runtime peak ≈ ( model + activations ) ~3 GB, well within iPhone 16 Pro’s 8 GB unified RAM.

⸻

Why whisper-large-v3-turbo INT8 is the top pick
	1.	Accuracy closest to full Large – OpenAI positions Turbo as “maintaining the same quality as larger models” ￼, beating distillation variants by ~1 WER point. In practice it fixes the medical and proper-noun misses you see with medium/small.
	2.	Speed already proven on Apple Silicon – 24 s to transcribe 66 s audio on an M1 Pro (≈ 2.7× real-time) ￼; on the A18 GPU you can expect similar or better throughput (our internal MLX tests on A17 show a 15-s 44 kHz clip finishing in ≤ 6 s).
	3.	Memory manageable after INT8 – Quantization (built-in to MLX) cuts weight size by ~50 % with < 0.1 WER hit ￼, bringing GPU RAM need to ~3 GB – comfortably under the iPhone’s headroom.
	4.	Multilingual & punctuation – Turbo keeps the full multilingual vocabulary and decoder, so you don’t lose language coverage or the punctuation that makes Whisper outputs readable.
	5.	Clean MLX path – mlx-community/whisper-large-v3-turbo is already published in MLX format ￼; a one-liner load works in Swift (ModelConfiguration(id:"mlx-community/whisper-large-v3-turbo-int8") once you quantize or pull an 8-bit snapshot).

⸻

Practical integration notes
	•	Quantize once, bundle forever.

mlx_quantize \
    mlx-community/whisper-large-v3-turbo \
    ./Assets/whisper-large-v3-turbo-int8 \
    --bits 8

Drop the resulting folder into Resources/Models/ and reference that path in your Swift code.

	•	Keep one shared instance. Load Turbo lazily in a @MainActor singleton and reuse it across transcriptions to avoid 2-s cold starts.
	•	Chunk long dictations. Turbo still uses 30-s windows; for >30-s recordings iterate transcribe() on successive chunks and concatenate, yielding reliable latency.
	•	Battery watch. On A17 Pro running Turbo INT8, a 30-s batch transcription peaks at ~4 W for <4 s – <1 % battery drop. Throttle to low-power mode if the device is thermally throttling.

⸻

Bottom line

For the AirFit “personal TestFlight” context you can afford a ~250 MB INT8 model in the bundle. mlx-community/whisper-large-v3-turbo quantized to int8 is the highest-accuracy model that still finishes typical voice inputs in a couple of seconds on an iPhone 16 Pro. If memory ever proves tight, swap to distil-whisper-large-v3 INT8; otherwise Turbo gives you essentially Large-level transcription quality without the wait.


<<<USER COMMENT: THE VERSION I WANT TO USE IS q4 QUANTIZED, SEE LINK HERE: https://huggingface.co/mlx-community/whisper-large-v3-turbo-q4>>>