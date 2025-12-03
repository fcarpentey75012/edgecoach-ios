# Backend - Routes Média Chat

Code Python à intégrer dans votre backend Flask EdgeCoach.

## Installation

```bash
pip install openai python-dotenv werkzeug pillow PyPDF2
```

## Configuration

Ajoutez dans votre `.env` :
```
OPENAI_API_KEY=sk-...
```

## Intégration

Dans votre `app.py` :

```python
from chat_media_routes import chat_media_bp

# Enregistrer le blueprint
app.register_blueprint(chat_media_bp)

# Configuration
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 25 * 1024 * 1024  # 25 MB

# Servir les fichiers uploadés (dev uniquement)
from flask import send_from_directory

@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)
```

## Endpoints

### POST /api/chat/transcribe
Transcription audio via Whisper.

**Request:** `multipart/form-data`
- `audio`: fichier audio (m4a, mp3, wav, webm)
- `language`: code ISO (optionnel, défaut: `fr`)

**Response:**
```json
{
    "success": true,
    "text": "Texte transcrit...",
    "duration": 5.2,
    "language": "fr"
}
```

### POST /api/chat/upload
Upload de fichiers (images, PDF).

**Request:** `multipart/form-data`
- `file`: fichier à uploader

**Response:**
```json
{
    "success": true,
    "file": {
        "id": "file_abc123",
        "type": "image",
        "fileName": "photo.jpg",
        "fileURL": "http://...",
        "thumbnailURL": "http://...",
        "fileSize": 123456,
        "mimeType": "image/jpeg"
    }
}
```

### DELETE /api/chat/files/<file_id>
Supprime un fichier uploadé.
