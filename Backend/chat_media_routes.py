"""
Routes API pour le Chat avec support Média
- Transcription vocale via OpenAI Whisper
- Upload de fichiers (images, PDF)

À intégrer dans votre backend Flask existant.

Installation requise:
    pip install openai python-dotenv werkzeug pillow PyPDF2

Configuration .env:
    OPENAI_API_KEY=sk-...
"""

import os
import uuid
import tempfile
from datetime import datetime
from functools import wraps

from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
from openai import OpenAI

# Blueprint pour les routes média du chat
chat_media_bp = Blueprint('chat_media', __name__, url_prefix='/api/chat')

# Configuration
ALLOWED_AUDIO_EXTENSIONS = {'m4a', 'mp3', 'wav', 'webm', 'ogg', 'flac'}
ALLOWED_IMAGE_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}
ALLOWED_DOCUMENT_EXTENSIONS = {'pdf', 'txt', 'md'}
MAX_AUDIO_SIZE = 25 * 1024 * 1024  # 25 MB (limite Whisper)
MAX_FILE_SIZE = 20 * 1024 * 1024   # 20 MB

# Client OpenAI (initialisé au premier appel)
_openai_client = None

def get_openai_client():
    """Récupère ou crée le client OpenAI."""
    global _openai_client
    if _openai_client is None:
        api_key = os.environ.get('OPENAI_API_KEY')
        if not api_key:
            raise ValueError("OPENAI_API_KEY non configurée dans les variables d'environnement")
        _openai_client = OpenAI(api_key=api_key)
    return _openai_client


def allowed_file(filename, allowed_extensions):
    """Vérifie si l'extension du fichier est autorisée."""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in allowed_extensions


def get_file_type(filename):
    """Détermine le type de fichier basé sur l'extension."""
    ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else ''

    if ext in ALLOWED_AUDIO_EXTENSIONS:
        return 'audio'
    elif ext in ALLOWED_IMAGE_EXTENSIONS:
        return 'image'
    elif ext in ALLOWED_DOCUMENT_EXTENSIONS:
        return 'document'
    return 'unknown'


# =============================================================================
# ROUTE: Transcription Audio (Whisper)
# =============================================================================

@chat_media_bp.route('/transcribe', methods=['POST'])
def transcribe_audio():
    """
    Transcrit un fichier audio en texte avec OpenAI Whisper.

    Request:
        - Content-Type: multipart/form-data
        - audio: fichier audio (m4a, mp3, wav, webm, ogg, flac)
        - language (optionnel): code langue ISO (ex: 'fr', 'en')

    Response:
        {
            "success": true,
            "text": "Texte transcrit...",
            "duration": 5.2,
            "language": "fr"
        }
    """
    try:
        # Vérifier la présence du fichier audio
        if 'audio' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Aucun fichier audio fourni'
            }), 400

        audio_file = request.files['audio']

        if audio_file.filename == '':
            return jsonify({
                'success': False,
                'error': 'Nom de fichier vide'
            }), 400

        # Vérifier l'extension
        if not allowed_file(audio_file.filename, ALLOWED_AUDIO_EXTENSIONS):
            return jsonify({
                'success': False,
                'error': f'Format audio non supporté. Formats acceptés: {", ".join(ALLOWED_AUDIO_EXTENSIONS)}'
            }), 400

        # Vérifier la taille
        audio_file.seek(0, 2)  # Aller à la fin
        file_size = audio_file.tell()
        audio_file.seek(0)  # Revenir au début

        if file_size > MAX_AUDIO_SIZE:
            return jsonify({
                'success': False,
                'error': f'Fichier trop volumineux. Maximum: {MAX_AUDIO_SIZE // (1024*1024)} MB'
            }), 400

        # Paramètres optionnels
        language = request.form.get('language', 'fr')  # Français par défaut

        # Sauvegarder temporairement le fichier
        ext = audio_file.filename.rsplit('.', 1)[1].lower()
        temp_filename = f"audio_{uuid.uuid4().hex}.{ext}"
        temp_path = os.path.join(tempfile.gettempdir(), temp_filename)

        try:
            audio_file.save(temp_path)

            # Appeler l'API Whisper
            client = get_openai_client()

            with open(temp_path, 'rb') as audio:
                transcript = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio,
                    language=language,
                    response_format="verbose_json"
                )

            return jsonify({
                'success': True,
                'text': transcript.text,
                'duration': getattr(transcript, 'duration', None),
                'language': language
            })

        finally:
            # Nettoyer le fichier temporaire
            if os.path.exists(temp_path):
                os.remove(temp_path)

    except ValueError as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    except Exception as e:
        current_app.logger.error(f"Erreur transcription: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Erreur lors de la transcription: {str(e)}'
        }), 500


# =============================================================================
# ROUTE: Upload de Fichiers
# =============================================================================

@chat_media_bp.route('/upload', methods=['POST'])
def upload_file():
    """
    Upload un fichier (image, PDF, document) pour le chat.

    Request:
        - Content-Type: multipart/form-data
        - file: le fichier à uploader
        - user_id (optionnel): ID de l'utilisateur

    Response:
        {
            "success": true,
            "file": {
                "id": "file_abc123",
                "type": "image",
                "fileName": "photo.jpg",
                "fileURL": "/uploads/chat/...",
                "thumbnailURL": "/uploads/chat/thumbs/...",
                "fileSize": 123456,
                "mimeType": "image/jpeg"
            }
        }
    """
    try:
        if 'file' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Aucun fichier fourni'
            }), 400

        uploaded_file = request.files['file']

        if uploaded_file.filename == '':
            return jsonify({
                'success': False,
                'error': 'Nom de fichier vide'
            }), 400

        # Vérifier le type de fichier
        all_allowed = ALLOWED_IMAGE_EXTENSIONS | ALLOWED_DOCUMENT_EXTENSIONS
        if not allowed_file(uploaded_file.filename, all_allowed):
            return jsonify({
                'success': False,
                'error': f'Format non supporté. Formats acceptés: {", ".join(all_allowed)}'
            }), 400

        # Vérifier la taille
        uploaded_file.seek(0, 2)
        file_size = uploaded_file.tell()
        uploaded_file.seek(0)

        if file_size > MAX_FILE_SIZE:
            return jsonify({
                'success': False,
                'error': f'Fichier trop volumineux. Maximum: {MAX_FILE_SIZE // (1024*1024)} MB'
            }), 400

        # Générer un nom unique
        original_filename = secure_filename(uploaded_file.filename)
        ext = original_filename.rsplit('.', 1)[1].lower() if '.' in original_filename else ''
        file_id = f"file_{uuid.uuid4().hex[:12]}"
        new_filename = f"{file_id}.{ext}"

        # Déterminer le type
        file_type = get_file_type(original_filename)

        # Créer le dossier d'upload si nécessaire
        upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
        chat_upload_folder = os.path.join(upload_folder, 'chat')
        os.makedirs(chat_upload_folder, exist_ok=True)

        # Sauvegarder le fichier
        file_path = os.path.join(chat_upload_folder, new_filename)
        uploaded_file.save(file_path)

        # Construire l'URL
        base_url = request.host_url.rstrip('/')
        file_url = f"{base_url}/uploads/chat/{new_filename}"

        # Créer une miniature pour les images
        thumbnail_url = None
        if file_type == 'image':
            thumbnail_url = create_thumbnail(file_path, chat_upload_folder, file_id, ext)
            if thumbnail_url:
                thumbnail_url = f"{base_url}/uploads/chat/thumbs/{file_id}_thumb.{ext}"

        # Extraire le texte pour les PDF (optionnel, pour l'IA)
        extracted_text = None
        if ext == 'pdf':
            extracted_text = extract_pdf_text(file_path)

        # Déterminer le MIME type
        mime_types = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp',
            'heic': 'image/heic',
            'pdf': 'application/pdf',
            'txt': 'text/plain',
            'md': 'text/markdown'
        }
        mime_type = mime_types.get(ext, 'application/octet-stream')

        response_data = {
            'success': True,
            'file': {
                'id': file_id,
                'type': file_type,
                'fileName': original_filename,
                'fileURL': file_url,
                'thumbnailURL': thumbnail_url,
                'fileSize': file_size,
                'mimeType': mime_type
            }
        }

        # Ajouter le texte extrait pour les documents
        if extracted_text:
            response_data['file']['extractedText'] = extracted_text[:5000]  # Limiter à 5000 chars

        return jsonify(response_data)

    except Exception as e:
        current_app.logger.error(f"Erreur upload: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Erreur lors de l\'upload: {str(e)}'
        }), 500


def create_thumbnail(image_path, upload_folder, file_id, ext):
    """Crée une miniature de l'image."""
    try:
        from PIL import Image

        thumbs_folder = os.path.join(upload_folder, 'thumbs')
        os.makedirs(thumbs_folder, exist_ok=True)

        thumb_filename = f"{file_id}_thumb.{ext}"
        thumb_path = os.path.join(thumbs_folder, thumb_filename)

        with Image.open(image_path) as img:
            # Convertir HEIC si nécessaire
            if img.mode in ('RGBA', 'P'):
                img = img.convert('RGB')

            # Créer la miniature (max 200x200)
            img.thumbnail((200, 200), Image.Resampling.LANCZOS)
            img.save(thumb_path, quality=85, optimize=True)

        return thumb_path

    except ImportError:
        current_app.logger.warning("Pillow non installé, pas de miniature créée")
        return None
    except Exception as e:
        current_app.logger.error(f"Erreur création miniature: {str(e)}")
        return None


def extract_pdf_text(pdf_path):
    """Extrait le texte d'un fichier PDF."""
    try:
        from PyPDF2 import PdfReader

        reader = PdfReader(pdf_path)
        text = ""
        for page in reader.pages[:10]:  # Limiter à 10 pages
            text += page.extract_text() + "\n"

        return text.strip()

    except ImportError:
        current_app.logger.warning("PyPDF2 non installé, pas d'extraction PDF")
        return None
    except Exception as e:
        current_app.logger.error(f"Erreur extraction PDF: {str(e)}")
        return None


# =============================================================================
# ROUTE: Suppression de Fichier
# =============================================================================

@chat_media_bp.route('/files/<file_id>', methods=['DELETE'])
def delete_file(file_id):
    """Supprime un fichier uploadé."""
    try:
        upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
        chat_upload_folder = os.path.join(upload_folder, 'chat')
        thumbs_folder = os.path.join(chat_upload_folder, 'thumbs')

        # Chercher et supprimer le fichier
        deleted = False
        for ext in (ALLOWED_IMAGE_EXTENSIONS | ALLOWED_DOCUMENT_EXTENSIONS):
            file_path = os.path.join(chat_upload_folder, f"{file_id}.{ext}")
            if os.path.exists(file_path):
                os.remove(file_path)
                deleted = True

                # Supprimer aussi la miniature si elle existe
                thumb_path = os.path.join(thumbs_folder, f"{file_id}_thumb.{ext}")
                if os.path.exists(thumb_path):
                    os.remove(thumb_path)
                break

        if deleted:
            return jsonify({'success': True})
        else:
            return jsonify({
                'success': False,
                'error': 'Fichier non trouvé'
            }), 404

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# =============================================================================
# Configuration à ajouter dans votre app Flask principale
# =============================================================================

"""
# Dans votre fichier app.py ou __init__.py, ajoutez:

from chat_media_routes import chat_media_bp

# Enregistrer le blueprint
app.register_blueprint(chat_media_bp)

# Configuration des uploads
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 25 * 1024 * 1024  # 25 MB max

# Servir les fichiers statiques (pour le développement)
from flask import send_from_directory

@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# N'oubliez pas d'ajouter OPENAI_API_KEY dans votre .env
"""
