import joblib
import numpy as np
import shap
import os
from dotenv import load_dotenv

load_dotenv()

pipeline       = joblib.load(os.getenv("MODEL_PATH", "model/model.joblib"))
label_encoder  = joblib.load(os.getenv("ENCODER_PATH", "model/label_encoder.joblib"))

xgb_model      = pipeline.named_steps['clf']
scaler         = pipeline.named_steps['Scaler']
explainer      = shap.TreeExplainer(xgb_model)

FEATURE_NAMES  = ['Age', 'SystolicBP', 'DiastolicBP', 'BS', 'BodyTemp', 'HeartRate']
HIGH_RISK_IDX  = list(label_encoder.classes_).index('high risk')

RECOMMENDATIONS = {
    'high risk': 'IMMEDIATE REFERRAL REQUIRED — Transfer patient to district hospital within 24 hours. Notify supervising clinician immediately.',
    'mid risk':  'REFER TO HEALTH CENTRE — Schedule facility visit within 72 hours. Increase antenatal monitoring frequency.',
    'low risk':  'ROUTINE MONITORING — Continue standard antenatal schedule. Educate patient on danger signs to watch for.',
}


def predict(features: dict) -> dict:
    feature_order = ['Age', 'SystolicBP', 'DiastolicBP', 'BS', 'BodyTemp', 'HeartRate']
    input_map = {
        'Age': features['age'],
        'SystolicBP': features['systolic_bp'],
        'DiastolicBP': features['diastolic_bp'],
        'BS': features['blood_sugar'],
        'BodyTemp': features['body_temp'],
        'HeartRate': features['heart_rate'],
    }
    X = np.array([[input_map[f] for f in feature_order]])
    X_scaled = scaler.transform(X)

    probs      = xgb_model.predict_proba(X_scaled)[0]
    pred_idx   = int(np.argmax(probs))
    risk_level = label_encoder.classes_[pred_idx]

    shap_vals = explainer.shap_values(X_scaled)
    shap_high = shap_vals[:, :, HIGH_RISK_IDX][0]

    shap_explanation = [
        {"feature": feat, "shap_value": round(float(sv), 4), "raw_value": float(input_map[feat])}
        for feat, sv in zip(feature_order, shap_high)
    ]
    shap_explanation.sort(key=lambda x: abs(x["shap_value"]), reverse=True)

    return {
        "risk_level":     risk_level,
        "confidence":     round(float(np.max(probs)), 4),
        "prob_high":      round(float(probs[HIGH_RISK_IDX]), 4),
        "prob_low":       round(float(probs[list(label_encoder.classes_).index('low risk')]), 4),
        "prob_mid":       round(float(probs[list(label_encoder.classes_).index('mid risk')]), 4),
        "recommendation": RECOMMENDATIONS[risk_level],
        "shap_values":    shap_explanation,
    }
