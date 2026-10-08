# TPPGPrintMargins

Typ in Unit `PPG.Print` - Basis `TPersistent`

Seitenränder beim Drucken in Millimetern.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Left` | `Integer` | `15` | Linker Rand in Millimetern vom Blattrand (0 bis 100, Standard 15). |
| `Top` | `Integer` | `15` | Oberer Rand in Millimetern vom Blattrand (0 bis 100, Standard 15). |
| `Right` | `Integer` | `15` | Rechter Rand in Millimetern vom Blattrand (0 bis 100, Standard 15). |
| `Bottom` | `Integer` | `15` | Unterer Rand in Millimetern vom Blattrand (0 bis 100, Standard 15). |

## Verwendet in

[TPPGGridPrinter](../TPPGGridPrinter.md), [TPPGKanbanPrinter](../TPPGKanbanPrinter.md), [TPPGPlannerPrinter](../TPPGPlannerPrinter.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
