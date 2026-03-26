import { User } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageContext";

interface PersonalInfo {
  fullName: string;
  phone: string;
  passportNumber: string;
  address: string;
}

interface Props {
  info: PersonalInfo;
  onChange: (info: PersonalInfo) => void;
}

const inputClass =
  "w-full bg-secondary border border-border rounded-md px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40";

const PersonalDetailsStep = ({ info, onChange }: Props) => {
  const { t } = useLanguage();
  const update = (field: keyof PersonalInfo, value: string) =>
    onChange({ ...info, [field]: value });

  return (
    <div className="bg-card border border-border rounded-xl p-6 space-y-4">
      <h2 className="text-lg font-semibold mb-2 flex items-center gap-2">
        <User className="h-5 w-5 text-primary" /> {t("booking.personalDetails") || "ব্যক্তিগত তথ্য"}
      </h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">
            {t("booking.fullName") || "পূর্ণ নাম"} <span className="text-destructive">*</span>
          </label>
          <input
            type="text"
            required
            maxLength={100}
            placeholder={t("booking.fullNamePlaceholder") || "আপনার পূর্ণ নাম লিখুন"}
            value={info.fullName}
            onChange={(e) => update("fullName", e.target.value)}
            className={inputClass}
          />
        </div>
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">
            {t("booking.phoneNumber") || "ফোন নম্বর"} <span className="text-destructive">*</span>
          </label>
          <input
            type="tel"
            required
            maxLength={15}
            placeholder="+880 1XXX-XXXXXX"
            value={info.phone}
            onChange={(e) => update("phone", e.target.value)}
            className={inputClass}
          />
        </div>
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">
            {t("booking.passportOptional") || "পাসপোর্ট নম্বর (ঐচ্ছিক)"}
          </label>
          <input
            type="text"
            required={false}
            maxLength={20}
            placeholder={t("booking.passportPlaceholder") || "পাসপোর্ট নম্বর"}
            value={info.passportNumber}
            onChange={(e) => update("passportNumber", e.target.value)}
            className={inputClass}
          />
        </div>
        <div>
          <label className="text-sm text-muted-foreground mb-1 block">
            {t("booking.address") || "ঠিকানা"}
          </label>
          <input
            type="text"
            maxLength={200}
            placeholder={t("booking.addressPlaceholder") || "আপনার ঠিকানা"}
            value={info.address}
            onChange={(e) => update("address", e.target.value)}
            className={inputClass}
          />
        </div>
      </div>
    </div>
  );
};

export default PersonalDetailsStep;
export type { PersonalInfo };
