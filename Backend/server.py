import shutil
from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin 
from firebase_admin import credentials, firestore, auth, storage
import asyncio
import random
import re
import os
import bcrypt
from werkzeug.utils import secure_filename
import cv2
import json
import numpy as np
import tensorflow as tf
from deepface import DeepFace
from pprint import pprint
import dlib
from imutils import face_utils
from scipy.spatial import distance as dist
import azure.cognitiveservices.speech as speechsdk
from moviepy.editor import VideoFileClip
from scipy.spatial.distance import euclidean
from fastdtw import fastdtw
import librosa


app = Flask(__name__)
cors = CORS(app, resources={r"/*": {"origins": "http://emac75.ddns.net:5555/"}})

# Inicialização da base de dados Firebase
cred = credentials.Certificate('ual-tech-firebase-adminsdk-p5fbv-f1103dd8a0.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Inicializa o detector de pontos faciais do Dlib
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

# Inicializa a configuração do Azure Speech
speech_key, service_region = "493fa347013244cba16555bb69a9a157", "westeurope"
language = "pt-PT"
speech_config = speechsdk.SpeechConfig(subscription=speech_key, region=service_region)
speech_config.speech_recognition_language = language

# Função para validar e-mails
def email_valido(email):
    pattern = r'^\S+@\S+\.\S+$'
    return re.match(pattern, email)

@app.route("/")
def helloworld():
    return "SERVER UP!"

# Endpoint para registar um novo utilizador
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    if not all(data[field] for field in ['username', 'email', 'password']):
        return jsonify({'success': False, 'message': 'Campos obrigatórios ausentes'}), 400
    if not email_valido(data['email']):
        return jsonify({'success': False, 'message': 'Formato de e-mail inválido'}), 400    
    print('-> REGISTER: Registo de utilizador: ' + data['username'])    
    try:
        existing_user = db.collection('Users').document(data['email']).get()
        if existing_user.exists:
            return jsonify({'success': False, 'message': 'E-mail já registado'}), 400
        hashed_password = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())
        hashed_password = hashed_password.decode('utf-8')
        user_info = {
            'username': data['username'],
            'email': data['email'],
            'password': hashed_password,
        }
        db.collection('Users').document(user_info['email']).set(user_info)
        return jsonify({'success': True, 'message': 'Utilizador registado com sucesso!'}), 201
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400

# Endpoint para login de utilizadores
@app.route('/login', methods=['POST'])
def login():
    data = request.json 
    if not all(data[field] for field in ['email', 'password']):
        print("-> LOGIN: Campos obrigatórios ausentes")
        return jsonify({'success': False, 'message': 'Campos obrigatórios ausentes'}), 400
    try:
        doc_ref = db.collection("Users").document(data['email'])
        doc = doc_ref.get()
        if doc.exists:
            user_data = doc.to_dict()
            hashed_password = user_data.get('password')
            if bcrypt.checkpw(data['password'].encode('utf-8'), hashed_password.encode('utf-8')):
                print("-> LOGIN: Login bem-sucedido!")
                return jsonify({'success': True, 'message': 'Login bem-sucedido!'}), 200
            else:
                print("-> LOGIN: Senha incorreta!")
                return jsonify({'success': False, 'message': 'Senha incorreta!'}), 401
        else:
            print("-> LOGIN: Utilizador não encontrado!")
            return jsonify({'success': False, 'message': 'Utilizador não encontrado!'}), 404
    except Exception as e:
        print("-> LOGIN: Erro ao fazer login:", e)
        return jsonify({'success': False, 'message': str(e)}), 400

# Endpoint para obter informações de um utilizador
@app.route('/userinfo', methods=['POST'])
def userinfo():
    data = request.json
    try:
        doc_ref = db.collection("Users").document(data['email'])
        doc = doc_ref.get()
        if doc.exists:
            doc_data = doc.to_dict()
            return jsonify({'success': True, 'message': 'Obtidos dados de Utilizador!', 'data': doc_data}), 200
        else:
            return jsonify({'success': False, 'message': 'Não exixtem dados de Utilizador!'}), 404
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400

# Endpoint para guardar obtidos pela câmera
@app.route('/camera_save', methods=['POST'])
def camera_save():
    if 'email' not in request.form:
        print("-> CAMERA_SAVE: Erro Email")
        return jsonify({'error': 'Email não fornecido'}), 400
    email = request.form['email']
    if 'frase' not in request.form:
        print("-> CAMERA_SAVE: Erro Frase")
        return jsonify({'error': 'Frase não fornecida'}), 400
    frase = request.form['frase']
    if 'video' not in request.files:
        print("-> CAMERA_SAVE: Erro Video")
        return jsonify({'error': 'Video não fornecido'}), 400
    file = request.files['video']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    filename = secure_filename(file.filename)
    os.makedirs(os.path.join(app.instance_path, email), exist_ok=True)
    file.save(os.path.join(app.instance_path, email, filename))
    return jsonify({'success': True}), 200

# Endpoint para registar um utilizador
@app.route('/register_user', methods=['POST'])
async def register_user():
    data = request.get_json()
    if not data or 'email' not in data:
        print("-> REGISTER_USER: Erro Email")
        return jsonify({'error': 'Email não fornecido'}), 400
    try:
        response_face = True
        response_phrase = True
        response_voice = True
        response_liveness = True
        response_face, response_phrase, response_voice, response_liveness = await asyncio.gather(face_register(data), recognize_speech(data), voice_register(data), liveness(data))
        if ((response_face) and (response_phrase) and (response_voice) and (response_liveness)):
            print('-> REGISTER_USER: Face:'+str(response_face)+' Frase:'+str(response_phrase)+' Liveness:'+str(response_liveness))
            message = 'Utilizador Registado!'
            success = True
        else:
            print('-> REGISTER_USER: Face:'+str(response_face)+' Frase:'+str(response_phrase)+' Liveness:'+str(response_liveness))
            message = 'Utilizador Não Registado!'
            success = False
            eliminar_cameradata(data['email'])
        delete_path = os.path.join(app.instance_path, f"{data['email']}/")
        delete_video(delete_path)
        return jsonify({'success': success, 'message': message, 'face': response_face, 'phrase': response_phrase, 'voice': response_voice, 'liveness': response_liveness}), 200
    except Exception as e:
        print(str(e))
        return jsonify({'error': str(e)}), 500

# Endpoint para validar um utilizador
@app.route('/validate_user', methods=['POST'])
async def validate_user():
    data = request.get_json()
    if not data or 'email' not in data:
        print("-> VALIDATE_USER: Erro Email")
        return jsonify({'error': 'Email não fornecido'}), 400
    try:
        response_face = True
        response_phrase = True
        response_voice = True
        response_liveness = True
        response_face, response_phrase, response_voice, response_liveness = await asyncio.gather(face_detect(data), recognize_speech(data), recognize_voice(data), liveness(data))
        if ((response_face) and (response_phrase) and (response_voice) and (response_liveness)):
            print('-> VALIDATE_USER: Face:'+str(response_face)+' Frase:'+str(response_phrase)+' Voz:'+str(response_voice)+' Liveness:'+str(response_liveness))
            message = 'Utilizador Validado!'
            success = True
        else:
            print('-> VALIDATE_USER: Face:'+str(response_face)+' Frase:'+str(response_phrase)+' Voz:'+str(response_voice)+' Liveness:'+str(response_liveness))
            message = 'Utilizador Não Validado!'
            success = False
        delete_path = os.path.join(app.instance_path, f"{data['email']}/")
        delete_video(delete_path)
        return jsonify({'success': success, 'message': message, 'face': response_face, 'phrase': response_phrase, 'voice': response_voice, 'liveness': response_liveness}), 200
    except Exception as e:
        print(str(e))
        return jsonify({'error': str(e)}), 500

# Endpoint para obter uma frase aletória da base de dados
@app.route('/phrase', methods=['POST'])
def phrase():
    try:
        phrase_id = random.randint(1, 100)
        doc_ref = db.collection("Frases").document('pt')
        doc = doc_ref.get()
        if doc.exists:
            phrase_data = doc.to_dict()
            if phrase_data[str(phrase_id)]:
                print('-> PHRASE: '+phrase_data[str(phrase_id)])
                return jsonify({'success': True, 'message': 'Obtidos dados de frases!', 'frase': phrase_data[str(phrase_id)]}), 200
            else:
                print(f"-> PHRASE: Frase com ID {phrase_id} não encontrada no documento.")
                return jsonify({'success': False, 'message': ''}), 404
        else:
            print('-> PHRASE: Erro a obter Frase: Documento não existe.')
    except Exception as e:
        print("-> PHRASE: Erro a obter Frase!:", e)
        return jsonify({'success': False, 'message': str(e)}), 400

# Eliminar videos guardados no servidor  
def delete_video(video_folder):
    for filename in os.listdir(video_folder):
        file_path = os.path.join(video_folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print(f'-> DELETE_VIDEO: Failed to delete {file_path}. Reason: {e}')

# Registar o rosto do utilizador
async def face_register(data):
    email = data['email']
    videofile = data['videofile']
    known_encodings = []
    face_confidence_counter = 0
    face_confidence_total = 0
    video_path = os.path.join(app.instance_path, f"{email}/{videofile}")
    if not os.path.exists(video_path):
        print("-> FACE_REGISTER: Erro Video")
        return(False)
    video_capture = cv2.VideoCapture(video_path)
    if not video_capture.isOpened():
        print("-> FACE_REGISTER: Erro Video")
        return(False)
    frame_count = int(video_capture.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = int(video_capture.get(cv2.CAP_PROP_FPS))
    duration = frame_count / fps
    interval = duration / 10
    for i in range(10):
        video_capture.set(cv2.CAP_PROP_POS_MSEC, i * interval * 1000)
        success, frame = video_capture.read()
        faces = DeepFace.extract_faces(img_path=frame, detector_backend='opencv', enforce_detection=False)
        detected_face = faces[0]["face"]  # Extract the face image
        face_confidence = faces[0]['confidence']
        output_file = f"{app.instance_path}/{email}/frame_reg_{i}.jpg"
        detected_face_write = detected_face * 255
        cv2.imwrite(output_file, detected_face_write[:, :, ::-1])
        if (face_confidence >= 0.90):
            face_confidence_counter = face_confidence_counter + 1
            face_confidence_total = face_confidence_total + face_confidence
            face_embedding = DeepFace.represent(img_path=detected_face_write, model_name='Facenet512', enforce_detection=False)[0]["embedding"]
            known_encodings.append(face_embedding)
            if len(known_encodings) >= 5:
                json_file_path = f"registered_user_encodings_{email}.json"
                with open(json_file_path, "w") as f:
                    json.dump(known_encodings, f)
                with open(json_file_path, "r") as j:
                    lista = json.load(j)
                    doc_ref = db.collection('Users').document(email)
                    doc_ref.update({'cameradata': json.dumps(lista)})
                video_capture.release()
                print(f'-> FACE_REGISTER: Reconhecimento: {face_confidence*100:.0f}%')
                return(True)
    return(False)

# Detetar o rosto do utilizador     
async def face_detect(data):
    try:
        # Definir variaveis
        count_auth = 0
        count_similarity = 0
        frame_attempts = 0
        face_result = 0
        face_count = 0
        registered_encodings = []
        email = data['email']
        videofile = data['videofile']
        video_path = os.path.join(app.instance_path, f"{email}/{videofile}")
        if not os.path.exists(video_path):
            print("-> FACE_DETECT: Erro Video")
            return(False)
        video_capture = cv2.VideoCapture(video_path)
        if not video_capture.isOpened():
            print("-> FACE_DETECT: Erro Video")
            return(False)
        try:
            doc_ref = db.collection('Users').document(email)
            doc = doc_ref.get()
            if doc.exists:
                registered_encodings.append(doc.to_dict().get("cameradata", None))
                registered_encodings = json.loads(registered_encodings[0])
                registered_encodings = [np.array(enc) for enc in registered_encodings]
            else:
                print("-> FACE_DETECT: Registo não encontrado na Base de Dados.")
                return(False)
        except FileNotFoundError:
            print("-> FACE_DETECT: Nenhum Utilizador registado encontrado. Por favor, registe um Utilizador primeiro.")
            return(False)
        video_capture = cv2.VideoCapture(video_path)
        if not video_capture.isOpened():
            print("-> FACE_DETECT: Erro a abrir Video.")
            return(False)
        frame_count = int(video_capture.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = int(video_capture.get(cv2.CAP_PROP_FPS))
        duration = frame_count / fps
        interval = duration / 10
        for i in range(10):
            video_capture.set(cv2.CAP_PROP_POS_MSEC, i * interval * 1000)
            success, frame = video_capture.read()
            faces = DeepFace.extract_faces(img_path=frame, detector_backend='opencv', enforce_detection=False)
            face_confidence = faces[0]['confidence']
            detected_face = faces[0]['face']  # Extract the face image
            output_file = f"{app.instance_path}/{email}/frame_val_{i}.jpg"
            detected_face_write = detected_face * 255
            cv2.imwrite(output_file, detected_face_write[:, :, ::-1])
            if (face_confidence >= 0.90):
                frame_attempts += 1
                face_embedding = DeepFace.represent(img_path=detected_face_write, model_name='Facenet512', enforce_detection=False)[0]["embedding"]
                matches = [np.linalg.norm(face_embedding - reg_enc) for reg_enc in registered_encodings]
                if(matches):
                    count_auth += 1
                for recorded_face in registered_encodings:
                    for j in range(5):
                        dot_product = np.dot(face_embedding, registered_encodings[j])
                        norm1 = np.linalg.norm(face_embedding)
                        norm2 = np.linalg.norm(recorded_face)
                        similarity = dot_product / (norm1 * norm2)
                        face_result = face_result + similarity
                        face_count = face_count + 1
                        if (similarity) > 0.5:
                            count_similarity += 1
        video_capture.release()
        if count_auth == 0:
            similarity_percent = 0
        else:
            similarity_percent =  round((count_similarity / (count_auth * 25)) * 100, 0)
        print(f'-> FACE_DETECT: # Autenticações:{str(count_auth)} / # Similaridades:{count_similarity}')
        if ((count_auth >= 5) and ((count_similarity/count_auth) > 15)):
            message = f'-> FACE_DETECT: Utilizador autorizado! Fotos:{str(count_auth)} Similaridades:{count_similarity} {similarity_percent:.0f}%'
            print(message)
            return(True)
        else:
            message = f'-> FACE_DETECT: Utilizador não autorizado! Fotos:{str(count_auth)} Similaridades:{count_similarity} {similarity_percent:.0f}%'
            print(message)
            return(False)
    except Exception as e:
        return(False)

# Fazer a prova de vida do utilizador
async def liveness(data):
    # Data
    email = data['email']
    videofile = data['videofile']
    video_path = os.path.join(app.instance_path, f"{email}/{videofile}")
    video = cv2.VideoCapture(video_path)
    # Limites para olhos e boca
    MAR_THRESH = 0.30
    MAR_CONSEC_FRAMES = 1
    # Movimento da cabeça
    prev_frame = None
    motion_threshold = 0.02
    motion_return = False
    # Contadores de frames
    mouth_counter = 0
    mouth_return = False
    # Índices dos marcos dos olhos e boca
    (mStart, mEnd) = face_utils.FACIAL_LANDMARKS_IDXS["mouth"]
    # Processar
    while video.isOpened():
        ret, frame = video.read()
        if not ret:
            break
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        rects = detector(gray, 0)
        for rect in rects:
            shape = predictor(gray, rect)
            shape = face_utils.shape_to_np(shape)
            # Boca
            mouth = shape[mStart:mEnd]
            mar = mouth_aspect_ratio(mouth)
            if mar > MAR_THRESH:
                mouth_counter += 1
                mouth_return = True
            else:
                if mouth_counter >= MAR_CONSEC_FRAMES:
                    mouth_counter += 1
                    mouth_return = True
        # Analise de movimento da cabeca
        if prev_frame is not None:
            frame_delta = cv2.absdiff(prev_frame, gray)
            thresh = cv2.threshold(frame_delta, 25, 255, cv2.THRESH_BINARY)[1]
            motion = np.sum(thresh) / (frame.shape[0] * frame.shape[1])
            # Considera movimento se a mudança for maior que o limite
            if motion > motion_threshold:
                motion_return = True
        prev_frame = gray.copy()
    print('-> LIVENESS: Boca movimentos: '+str(mouth_counter))
    print('-> LIVENESS: Motion valor: '+str(motion))
    # Liberta video
    video.release()
    if ((motion_return) and (mouth_return)):
        return(True)
    else:
        return(False)

# Reconhecer a fala do utilizador
async def recognize_speech(data):
    try:
        email = data['email']
        frase = data['frase']
        frase_rec = ''
        videofile = data['videofile']
        video_path = os.path.join(app.instance_path, f"{email}/{videofile}")
        try:
            video_clip = VideoFileClip(video_path)
            audio_path = os.path.join(app.instance_path, f"{email}/audio.wav")
            video_clip.audio.write_audiofile(audio_path, codec='pcm_s16le')  # Salvar como WAV
        except Exception as e:
            print(f"-> RECOGNIZE_SPEECH: Erro ao extrair áudio: {e}")
            return jsonify({'error': 'Erro ao extrair áudio do vídeo'}), 500
        audio_config = speechsdk.audio.AudioConfig(filename=audio_path)
        speech_recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)
        result = speech_recognizer.recognize_once()
        if result.reason == speechsdk.ResultReason.RecognizedSpeech:
            frase_rec = format(result.text)
            print("-> RECOGNIZE_SPEECH: Frase Original: "+frase.lower()[:-1])
            print("-> RECOGNIZE_SPEECH: Frase Reconhecida: "+frase_rec.lower()[:-1])
            if (frase.lower()[:-1] == frase_rec.lower()[:-1]):
                return(True)
            else:
                return(False)
        elif result.reason == speechsdk.ResultReason.NoMatch:
            return(False)
        elif result.reason == speechsdk.ResultReason.Canceled:
            return(False)
    except Exception as e:
        print(str(e))
        return(False)

# Função para calcular o aspeto do olho
def eye_aspect_ratio(eye):
    A = np.linalg.norm(eye[1] - eye[5])
    B = np.linalg.norm(eye[2] - eye[4])
    C = np.linalg.norm(eye[0] - eye[3])
    ear = (A + B) / (2.0 * C)
    return ear

# Função para calcular o aspecto da boca
def mouth_aspect_ratio(mouth):
    A = dist.euclidean(mouth[3], mouth[9])
    B = dist.euclidean(mouth[0], mouth[6])
    mar = A / B
    return mar

# Eliminar dados biométricos de um utilizador
def eliminar_cameradata(email):
    doc_ref = db.collection('Users').document(email)
    doc_ref.update({'cameradata': firestore.DELETE_FIELD})
    doc_ref.update({'voicefeatures': firestore.DELETE_FIELD})

# Carregar áudio de um ficheiro
def carregar_audio(file_path, sample_rate=22050):
    audio, sr = librosa.load(file_path, sr=sample_rate)
    audio = librosa.util.normalize(audio)
    return audio, sr

# Extrair características do áudio
def extrair_features(audio, sr, n_mfcc=13):
    mfccs = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=n_mfcc)
    chroma = librosa.feature.chroma_stft(y=audio, sr=sr)
    mel = librosa.feature.melspectrogram(y=audio, sr=sr)
    contrast = librosa.feature.spectral_contrast(y=audio, sr=sr)
    
    features = np.concatenate((mfccs, chroma, mel, contrast), axis=0)
    return features

# Remover silêncios do áudio
def remove_silence(y):
    non_silent_intervals = librosa.effects.split(y, top_db=20)
    non_silent_audio = np.concatenate([y[start:end] for start, end in non_silent_intervals])
    return non_silent_audio

# Calcular a distância DTW entre duas sequências de características
def calcular_distancia_dtw(features1, features2):
    distancia, _ = fastdtw(features1.T, features2.T, dist=euclidean)
    return distancia

# Extrair características devoz de um áudio
def feature_voz(audio_path):
    audio, sr1 = carregar_audio(audio_path)

    audio = remove_silence(audio)

    features = extrair_features(audio, sr1)

    return features

# Reconhecer a voz de um utilizador
async def recognize_voice(data):
    try:
        email = data['email']
        videofile = data['videofile']
        video_path = os.path.join(app.instance_path, f"{email}/{videofile}")
        try:
            video_clip = VideoFileClip(video_path)
            audio_path = os.path.join(app.instance_path, f"{email}/detect_audio.wav")
            video_clip.audio.write_audiofile(audio_path, codec='pcm_s16le')  # Salvar como WAV
            user_ref = db.collection("Users").document(email)
            user_data = user_ref.get()
            if user_data.exists:
                voice_features_json = user_data.to_dict().get('voicefeatures', '{}')
                voice_features_list = json.loads(voice_features_json) 
                voice_features_array = np.array(voice_features_list)
                distancia = calcular_distancia_dtw(feature_voz(audio_path), voice_features_array)
                if os.path.exists(audio_path):
                    os.remove(audio_path)
                if distancia < 41688:
                    print('-> RECOGNIZE_VOICE: Autenticado com sucesso! Distância:' + str(distancia))
                    return(True)
                else:
                    print('-> RECOGNIZE_VOICE: Falha na autenticação: Voz não reconhecida! Distância:' + str(distancia))
                    return(False)
            else:
                print("-> RECOGNIZE_VOICE: Utilizador não encontrado na Base de Dados.")
                return(False)
        except Exception as e:
            print(f"-> RECOGNIZE_VOICE: Erro ao extrair áudio: {e}")
            return(False)
    except Exception as e:
        print(str(e))
        return(False)

# Registar a voz de um utilizador  
async def voice_register(data):
    try:
        email = data['email']
        videofile = data['videofile']
        video_path = os.path.join(app.instance_path, f"{email}/{videofile}")
        try:
            video_clip = VideoFileClip(video_path)
            audio_path = os.path.join(app.instance_path, f"{email}/register_audio.wav")
            video_clip.audio.write_audiofile(audio_path, codec='pcm_s16le')  # Salvar como WAV
            features_json = feature_voz(audio_path).tolist()
            doc_ref = db.collection('Users').document(email)
            doc_ref.update({'voicefeatures': json.dumps(features_json)})
            print("-> VOICE_REGISTER: Utilizador registado na Base de Dados.")
            return(True)
        except Exception as e:
            print(f"-> VOICE_REGISTER: Erro ao extrair áudio: {e}")
            return(False)
    except Exception as e:
        print(str(e))
        return(False)

#Start Server
if __name__ == '__main__':
    app.run(
        debug=True,
        host="0.0.0.0",
        port=5555
        )
