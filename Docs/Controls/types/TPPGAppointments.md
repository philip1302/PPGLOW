# TPPGAppointments

Typ in Unit `PPG.Planner.Model` - Basis `TOwnedCollection`

Die Termine des Planers (Collection). Termine mit Wiederholung, Ressource, Kategorie und Ort; alternativ liefert eine eigene Quelle (Source bzw. der DB-Planer) die Termine.

Nutzung: `with PPGPlanner1.Appointments.AddAppointment(Start, Ende, 'Besprechung') do Location := 'Raum 2';`

Collection: Die Eintraege sind vom Typ [TPPGAppointment](TPPGAppointment.md). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber `Add`, `Items[i]`, `Count`, `Delete`, `Clear`.

## Verwendet in

[TPPGPlanner](../TPPGPlanner.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
