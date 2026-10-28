# S21 Lock-screen notification

Prototype: [lock-notification.html](lock-notification.html).

**Purpose:** for most of a trek the phone is locked and music is playing; the notification is the app.

## States and copy
| State | Line 1 | Line 2 | Actions |
|---|---|---|---|
| Tracking | Tracking · 2.4 km walked | +180 m climb · battery 78% · solo | Emergency card, SOS |
| SOS active | SOS active (red) | SMS delivered to 2 of 3 · beacon on | Emergency card, Call 112 |
| Core stopped | Trek engine stopped | Restarting it now. SOS messages still go out. | none |
| After reboot | Tap to resume trek | The phone restarted. Open Pagdandi to keep tracking. | tap opens the app |

## Rules
SOS from the notification only opens the hold-to-confirm screen over the lock screen; it never sends by itself (pocket-safe). Talk and Check-in actions arrive with PTT (M3) and check-in (M2); route instructions in line 1 arrive with navigation (M2).
