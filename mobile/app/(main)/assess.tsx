import { useState } from "react";
import { View, Text, TextInput, ScrollView, KeyboardAvoidingView, Platform } from "react-native";
import { useTranslation } from "react-i18next";
import { useRouter } from "expo-router";
import { useAssessmentStore } from "../../stores/assessmentStore";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import Icon from "../../components/ui/Icon";
import type { AssessmentPayload } from "../../types";

interface FieldDef {
  key: keyof AssessmentPayload;
  label: string;
  min: number;
  max: number;
  placeholder: string;
}

const FIELDS: FieldDef[] = [
  { key: "age", label: "age", min: 10, max: 60, placeholder: "25" },
  { key: "systolic_bp", label: "systolic_bp", min: 70, max: 200, placeholder: "120" },
  { key: "diastolic_bp", label: "diastolic_bp", min: 40, max: 120, placeholder: "80" },
  { key: "blood_sugar", label: "blood_sugar", min: 4, max: 25, placeholder: "7.0" },
  { key: "body_temp", label: "body_temp", min: 95, max: 105, placeholder: "98.6" },
  { key: "heart_rate", label: "heart_rate", min: 40, max: 100, placeholder: "72" },
];

export default function AssessPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const submitAssessment = useAssessmentStore((s) => s.submitAssessment);
  const [patientRef, setPatientRef] = useState("");
  const [values, setValues] = useState<Record<string, string>>({});
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const update = (key: string, val: string) => setValues((p) => ({ ...p, [key]: val }));

  const handleSubmit = async () => {
    setError("");
    setLoading(true);
    try {
      const payload: AssessmentPayload = { age: 0, systolic_bp: 0, diastolic_bp: 0, blood_sugar: 0, body_temp: 0, heart_rate: 0 };
      if (patientRef) payload.patient_ref = patientRef;
      FIELDS.forEach((f) => { (payload as any)[f.key] = parseFloat(values[f.key] || "0"); });
      const result = await submitAssessment(payload);
      useAssessmentStore.getState().setLastResult(result);
      router.push("/(main)/result");
    } catch (err: any) {
      if (err.message === "OFFLINE_QUEUED") {
        setError("Saved offline — will sync when connection is restored.");
      } else {
        setError(t("error"));
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} className="flex-1 bg-canvas">
      <ScrollView className="flex-1" contentContainerStyle={{ padding: 20, paddingBottom: 100 }}>
        <Text className="text-2xl font-bold text-text-heading tracking-tight mb-1">{t("new_assessment")}</Text>
        <Text className="text-sm text-text-muted mb-6">{t("enter_patient_data")}</Text>

        {error ? (
          <View className="mb-5 bg-red-50 border border-red-200 rounded-xl px-4 py-3">
            <Text className="text-red-700 text-sm">{error}</Text>
          </View>
        ) : null}

        <Text className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">{t("patient_ref")}</Text>
        <TextInput
          value={patientRef}
          onChangeText={setPatientRef}
          placeholder={t("enter_patient_id")}
          className="w-full px-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading mb-6"
          placeholderTextColor="#8E8696"
        />

        <Card className="mb-6">
          <Text className="text-sm font-semibold text-text-heading mb-4">{t("enter_patient_data")}</Text>
          <View className="gap-3">
            {FIELDS.map((f) => (
              <View key={f.key}>
                <Text className="text-xs font-medium text-text-muted mb-1.5">{t(f.label)}</Text>
                <TextInput
                  keyboardType="decimal-pad"
                  value={values[f.key] || ""}
                  onChangeText={(v) => update(f.key, v)}
                  placeholder={f.placeholder}
                  className="w-full px-4 py-2.5 bg-surface border border-border rounded-xl text-sm text-text-heading"
                  placeholderTextColor="#8E8696"
                />
                <Text className="text-[11px] text-text-muted mt-1">{f.min} – {f.max}</Text>
              </View>
            ))}
          </View>
        </Card>

        <Button onPress={handleSubmit} loading={loading}>
          {t("assess_risk")}
        </Button>

        <View className="flex-row items-start gap-2 mt-4 px-1">
          <Icon name="information-circle" size={18} color="#8E8696" className="mt-0.5" />
          <Text className="text-xs text-text-muted leading-relaxed flex-1">{t("clinical_summary")}</Text>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
