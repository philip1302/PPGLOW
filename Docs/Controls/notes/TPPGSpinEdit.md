**Vorbild:** TSpinEdit (Vcl.Samples.Spin)

## Unterschiede und Hinweise

- `MinValue > MaxValue` wirft **nicht** (wie `TSpinEdit`), sonst scheitert `MinValue := 10; MaxValue := 100`.
- Wiederholung beim Halten der Buttons über den Animator.
