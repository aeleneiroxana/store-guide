# Run pip install SpeechRecognition
# Also install pyAudio package
import speech_recognition as sr


r = sr.Recognizer()

with sr.Microphone(2) as source:
    print("I am listening to you!")
    print(sr.Microphone.list_microphone_names())
    # r.adjust_for_ambient_noise(source)
    audio = r.listen(source)
    try:
        text = r.recognize_google(audio)
        print('You said: {}'.format(text))
    except:
        print('Sorry I was not able to recognize your voice')

