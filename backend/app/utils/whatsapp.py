"""WhatsApp message templates for ANC visit scheduler reminders.

All builder functions are pure — they accept parameters and return a
formatted string. The actual sending is handled by services.delivery.send_whatsapp.
"""


def build_48h_reminder(patient_name: str, visit_number: int,
                        visit_label: str, visit_date: str,
                        facility: str, chw_name: str,
                        chw_phone: str, lang: str = "fr") -> str:
    """Build the 48-hour advance reminder WhatsApp message."""
    if lang == "en":
        return (
            f"\U0001f475 *MamaSafe — Antenatal Visit Reminder*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your next antenatal visit is scheduled for:\n\n"
            f"\U0001f4c5 *{visit_date}*\n"
            f"\U0001f3e5 *{facility}*\n"
            f"\U0001f469\u200d\u2695\ufe0f *CHW: {chw_name}*\n\n"
            f"This is your *Visit {visit_number} — {visit_label}*.\n\n"
            f"\U0001f4cb *Please bring:*\n"
            f"• Maternal health booklet\n"
            f"• Previous test results\n"
            f"• Identity document\n\n"
            f"If you cannot attend, please contact your CHW:\n"
            f"\U0001f4de {chw_phone}\n\n"
            f"_MamaSafe supports you throughout your pregnancy._"
        )
    return (
        f"\U0001f475 *MamaSafe — Rappel de visite prénatale*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre prochaine visite prénatale est prévue pour :\n\n"
        f"\U0001f4c5 *{visit_date}*\n"
        f"\U0001f3e5 *{facility}*\n"
        f"\U0001f469\u200d\u2695\ufe0f *Agent de santé : {chw_name}*\n\n"
        f"Il s'agit de votre *visite n°{visit_number} — {visit_label}*.\n\n"
        f"\U0001f4cb *À apporter :*\n"
        f"• Carnet de santé maternelle\n"
        f"• Résultats d'analyses précédents\n"
        f"• Pièce d'identité\n\n"
        f"En cas d'empêchement, contactez votre agent de santé :\n"
        f"\U0001f4de {chw_phone}\n\n"
        f"_MamaSafe vous accompagne tout au long de votre grossesse._"
    )


def build_day_reminder(patient_name: str, visit_number: int,
                       facility: str, lang: str = "fr") -> str:
    """Build the same-day reminder message."""
    if lang == "en":
        return (
            f"\U0001f514 *MamaSafe — Visit Today*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your antenatal visit is *today* — Visit {visit_number}!\n\n"
            f"\U0001f3e5 {facility}\n"
            f"\u23f0 Please come as early as possible today.\n\n"
            f"Don't forget your health booklet \U0001f4cb\n\n"
            f"_Wishing you and your baby good health_ \U0001f476"
        )
    return (
        f"\U0001f514 *MamaSafe — Visite aujourd'hui*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre visite prénatale est *aujourd'hui* — Visite n°{visit_number} !\n\n"
        f"\U0001f3e5 {facility}\n"
        f"\u23f0 Venez dès que possible dans la journée.\n\n"
        f"N'oubliez pas votre carnet de santé \U0001f4cb\n\n"
        f"_Bonne santé à vous et votre bébé_ \U0001f476"
    )


def build_chw_daily_list(chw_name: str,
                          visits: list, date_str: str) -> str:
    """Build the CHW morning patient list message."""
    if not visits:
        return (
            f"\U0001f4cb *MamaSafe — Patients du jour*\n"
            f"{date_str}\n\n"
            f"Bonjour {chw_name},\n\n"
            f"Aucune visite prénatale prévue aujourd'hui. \u2705\n\n"
            f"_Bonne journée !_"
        )
    lines = "\n\n".join([
        f"{i+1}. \U0001f464 *{v['patient_name']}* — Visite n°{v['visit_number']} "
        f"({v['label']})\n   \U0001f4de {v['patient_phone'] or 'Pas de numéro'}"
        for i, v in enumerate(visits)
    ])
    return (
        f"\U0001f4cb *MamaSafe — Patients du jour*\n"
        f"{date_str}\n\n"
        f"Bonjour {chw_name},\n\n"
        f"Vous avez *{len(visits)} visite(s) prénatale(s)* prévue(s) "
        f"aujourd'hui :\n\n"
        f"{lines}\n\n"
        f"Bonne journée sur le terrain ! \U0001f4aa\n_MamaSafe_"
    )


def build_missed_visit_alert(chw_name: str,
                              missed: list, date_str: str) -> str:
    """Build the missed visit alert for CHW."""
    lines = "\n\n".join([
        f"• *{v['patient_name']}* — Visite n°{v['visit_number']}\n"
        f"  \U0001f4de {v['patient_phone'] or 'Pas de numéro'} — Veuillez la contacter"
        for v in missed
    ])
    return (
        f"\u26a0\ufe0f *MamaSafe — Visites manquées*\n"
        f"{date_str}\n\n"
        f"Bonjour {chw_name},\n\n"
        f"*{len(missed)} patient(s)* n'ont pas effectué leur visite "
        f"aujourd'hui :\n\n"
        f"{lines}\n\n"
        f"Ces visites sont marquées comme *manquées* dans MamaSafe.\n"
        f"Vous pouvez les reprogrammer depuis l'application."
    )


def build_reschedule_confirmation(patient_name: str,
                                   visit_number: int,
                                   new_date: str,
                                   facility: str,
                                   lang: str = "fr") -> str:
    """Confirm rescheduled visit to patient."""
    if lang == "en":
        return (
            f"\U0001f4c5 *MamaSafe — Visit Rescheduled*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your Visit {visit_number} has been rescheduled to:\n\n"
            f"\U0001f4c5 *{new_date}*\n"
            f"\U0001f3e5 {facility}\n\n"
            f"Please save this new date. \U0001f4cb\n\n"
            f"_MamaSafe_"
        )
    return (
        f"\U0001f4c5 *MamaSafe — Visite reprogrammée*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre visite n°{visit_number} a été reprogrammée au :\n\n"
        f"\U0001f4c5 *{new_date}*\n"
        f"\U0001f3e5 {facility}\n\n"
        f"Veuillez noter cette nouvelle date. \U0001f4cb\n\n"
        f"_MamaSafe_"
    )


# ── POSTNATAL CARE REMINDERS ──────────────────────────────

def build_pnc_reminder(patient_name: str, visit_number: int,
                       visit_label: str, visit_date: str,
                       facility: str, chw_name: str,
                       chw_phone: str, lang: str = "fr") -> str:
    """Build the 48-hour advance reminder for a postnatal visit."""
    if lang == "en":
        return (
            f"\U0001f476 *MamaSafe — Postnatal Visit Reminder*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your next postnatal visit is scheduled for:\n\n"
            f"\U0001f4c5 *{visit_date}*\n"
            f"\U0001f3e5 *{facility}*\n"
            f"\U0001f469\u200d\u2695\ufe0f *CHW: {chw_name}*\n\n"
            f"This is your *{visit_label}*.\n\n"
            f"\U0001f4cb *Please bring:*\n"
            f"• Maternal and baby health booklet\n"
            f"• Baby's vaccination card\n\n"
            f"If you cannot attend, please contact your CHW:\n"
            f"\U0001f4de {chw_phone}\n\n"
            f"_MamaSafe supports you and your newborn._"
        )
    return (
        f"\U0001f476 *MamaSafe — Rappel de visite postnatale*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre prochaine visite postnatale est prévue pour :\n\n"
        f"\U0001f4c5 *{visit_date}*\n"
        f"\U0001f3e5 *{facility}*\n"
        f"\U0001f469\u200d\u2695\ufe0f *Agent de santé : {chw_name}*\n\n"
        f"Il s'agit de votre *{visit_label}*.\n\n"
        f"\U0001f4cb *À apporter :*\n"
        f"• Carnet de santé maternel et bébé\n"
        f"• Carnet de vaccination du bébé\n\n"
        f"En cas d'empêchement, contactez votre agent de santé :\n"
        f"\U0001f4de {chw_phone}\n\n"
        f"_MamaSafe vous accompagne avec votre nouveau-né._"
    )


def build_pnc_day_reminder(patient_name: str, visit_number: int,
                           visit_label: str, facility: str,
                           lang: str = "fr") -> str:
    """Build the same-day reminder for a postnatal visit."""
    if lang == "en":
        return (
            f"\U0001f514 *MamaSafe — Postnatal Visit Today*\n\n"
            f"Hello {patient_name},\n\n"
            f"Your postnatal visit is *today* — {visit_label}!\n\n"
            f"\U0001f3e5 {facility}\n"
            f"\u23f0 Please come as early as possible today.\n\n"
            f"Don't forget your baby's vaccination card \U0001f4cb\n\n"
            f"_Wishing you and your baby good health_ \U0001f476"
        )
    return (
        f"\U0001f514 *MamaSafe — Visite postnatale aujourd'hui*\n\n"
        f"Bonjour {patient_name},\n\n"
        f"Votre visite postnatale est *aujourd'hui* — {visit_label} !\n\n"
        f"\U0001f3e5 {facility}\n"
        f"\u23f0 Venez dès que possible dans la journée.\n\n"
        f"N'oubliez pas le carnet de vaccination du bébé \U0001f4cb\n\n"
        f"_Bonne santé à vous et votre bébé_ \U0001f476"
    )
