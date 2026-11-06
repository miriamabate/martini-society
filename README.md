# 🍸 Martini Society

La nostra app per organizzare le serate. Gira sul PC di una di noi, le altre entrano dal telefono.

## In locale

Serve solo **Python 3** (su Mac c'è già, su Windows si scarica da python.org). Non c'è niente da installare.

```bash
cd martini-society
python3 server.py
```

Nel terminale compaiono due indirizzi:

- **Sul tuo PC:** http://localhost:8000
- **Per le amiche sulla stessa Wi-Fi:** http://192.168.x.x:8000 (aprilo dal telefono e aggiungilo alla schermata Home: sembra un'app vera)

I font sono inclusi nella cartella `docs/fonts` (Bodoni Moda e Manrope, licenza OFL), quindi l'app funziona anche offline.

Su Windows usa `python server.py`. Se il firewall chiede il permesso, consenti l'accesso sulle **reti private**.

## Primo avvio

1. Vai su **Le amiche** e crea un profilo per ognuna, con numero di telefono e prefisso.
2. Ognuna, dal proprio telefono, sceglie **chi è** in alto a destra. La scelta resta salvata su quel dispositivo.

## Cosa c'è

| Sezione | Cosa fa |
|---|---|
| 🗓 **Calendario** | Vista del mese con tre tipi di piano: serata/evento, appuntamento e chiamata. Ognuna preme "Ci sono!" per confermare. |
| 🍸 **Locali** | Ognuna vota da 1 a 5 cibo, drink, prezzo, gente, musica, atmosfera e servizio, poi aggiunge "ci torneresti?", il drink preso e un commento. L'app fa le medie, le classifiche e la Hall of Fame. |
| 🗳️ **Sondaggi** | Per ogni serata create un sondaggio con più opzioni (dove, cosa, dress code…). Ognuna vota toccando un'opzione, si vede chi ha votato e chi manca; chiuso il sondaggio, l'opzione vincente si aggiunge al calendario con un tocco. |
| 🎡 **Da provare** | I posti che vogliamo provare. "Ci voglio andare" funziona come un voto, la **Ruota** sceglie a caso (vince più spesso chi ha più voti), "Fatto!" sposta il posto tra i Locali così lo votate. |
| 👠 **Le amiche** | I profili, con colore, simbolo e motto. |

## WhatsApp e FaceTime

L'app usa i **link ufficiali** dei due servizi, che funzionano senza API e senza account business:

- **💬 Manda sul gruppo WhatsApp**: apre WhatsApp con il messaggio già scritto. Scegli il gruppo e invii.
- **Chiamate**: nell'evento puoi incollare il **link della chiamata di gruppo** (da WhatsApp: *Chiamate → Crea link*; da FaceTime: *Crea link*). Così tutte entrano con un tap.
- **Pulsanti diretti** per ogni amica: `wa.me/numero` per WhatsApp e `facetime://` per FaceTime. FaceTime funziona solo su iPhone, iPad e Mac.
- **📲 Aggiungi al mio calendario** scarica un file `.ics` con promemoria un'ora prima. Si apre con il calendario di iPhone, Google o Outlook.

L'app non può far partire una chiamata o mandare un messaggio da sola: Apple e Meta non lo permettono a app esterne. Prepara tutto, e l'ultimo tap tocca a voi.

## Dati e backup

In modalità locale tutto viene salvato in `data.json`, nella cartella dell'app. Per fare un backup basta copiare quel file.

## Online su GitHub Pages (da ovunque, PC spento)

GitHub Pages pubblica solo le pagine, non può salvare dati. I dati vanno quindi su **Supabase**, un database gratuito, e sono protetti da una **parola d'ordine del club**.

### 1. Il database e gli accessi (automatico con GitHub Actions)
1. Crea un progetto su [supabase.com](https://supabase.com). Il piano Free basta.
2. **Accessi:** in Supabase → **Authentication**:
   - in **Sign In / Providers** lascia attivo **Email** e **disattiva "Allow new users to sign up"**, così nessuno può crearsi un account da solo;
   - in **Users → Add user → Create new user** crea un account per ognuna (email + password, con **Auto Confirm User** spuntato).
3. Nel repo GitHub apri **Settings → Secrets and variables → Actions** e aggiungi:
   - `SUPABASE_DB_URL`: in Supabase premi **Connect**, scegli **Session pooler** e copia l'URI, sostituendo `[YOUR-PASSWORD]` con la password del database;
   - `CLUB_EMAILS`: le email ammesse, separate da virgola (es. `miriam@…, giulia@…`).
4. Il workflow **Database** applica le migrazioni in `supabase/migrations/` e aggiorna la lista del club a ogni push su `supabase/`. Per lanciarlo a mano: **Actions → Database → Run workflow**.

**Togliere l'accesso a qualcuna:** levala da `CLUB_EMAILS` e rilancia il workflow, poi eliminala anche da Authentication → Users.

### 2. La configurazione
Apri `docs/config.js` e incolla URL e chiave publishable: possono stare in un repo pubblico, da sole non danno accesso ai dati.

### 3. La pubblicazione (GitHub Pages)
1. Su GitHub crea un repo nuovo, per esempio `martini-society`.
2. Carica i file, trascinandoli in **Add file → Upload files** oppure così:
   ```bash
   git init && git add . && git commit -m "Martini Society 🍸"
   git branch -M main
   git remote add origin https://github.com/TUO-UTENTE/martini-society.git
   git push -u origin main
   ```
3. Vai su **Settings → Pages → Build and deployment**, scegli *Deploy from a branch*, poi **main** e la cartella **/docs**, e premi **Save**.
4. Dopo un minuto l'app è su `https://TUO-UTENTE.github.io/martini-society/`. Mandate il link e la parola d'ordine sul gruppo.

### Da sapere
- Il **sito** di GitHub Pages è sempre pubblico, ma senza parola d'ordine si vede solo la schermata "Solo su invito". Numeri, piani e voti restano nel database.
- Usate una parola d'ordine **lunga**, tipo una frase. Per cambiarla: `update private.club set secret = 'nuova-frase';` nel SQL Editor. A quel punto l'app la richiede a tutte.
- Se `config.js` è vuoto, l'app torna in modalità locale con `python3 server.py`.
- Su Supabase Free i progetti senza attività per 7 giorni vengono messi in pausa. Si riattivano dalla dashboard con un clic.

## Sticker personalizzati
Nella cartella `docs/stickers/` puoi mettere dei PNG con lo sfondo trasparente (`cosmo.png`, `gift.png`, `city.png`, `kiss.png`, `legs.png`, `taxi.png`): l'app li usa al posto dei disegni. Ricorda che su GitHub Pages il sito, e quindi anche le immagini, è pubblico.

## Come app sul telefono
L'app si installa sul telefono come app web (PWA), con la sua icona e a schermo intero:
- **iPhone:** apri il link in **Safari**, poi **Condividi** e **Aggiungi alla schermata Home**.
- **Android:** apri il link in **Chrome**, poi il menu **⋮** e **Installa app** (o "Aggiungi a schermata Home").

Al primo avvio dall'icona l'app chiede di nuovo email e password: è normale, una volta sola.
