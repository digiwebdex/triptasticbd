import { useState, useRef } from "react";
import { Upload, FileText, Trash2, Check, Loader2, AlertCircle } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageContext";

export interface UploadedDoc {
  type: string;
  file: File;
  preview?: string;
}

interface Props {
  documents: UploadedDoc[];
  onChange: (docs: UploadedDoc[]) => void;
}

const DOC_TYPES = [
  { key: "passport", labelEn: "Passport Copy", labelBn: "পাসপোর্ট কপি" },
  { key: "nid", labelEn: "NID / National ID", labelBn: "এনআইডি / জাতীয় পরিচয়পত্র" },
  { key: "photo", labelEn: "Passport Size Photo", labelBn: "পাসপোর্ট সাইজ ফটো" },
] as const;

const DocumentUploadStep = ({ documents, onChange }: Props) => {
  const { t } = useLanguage();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [activeType, setActiveType] = useState<string>("");

  const getDocForType = (type: string) => documents.find((d) => d.type === type);

  const handleFile = (file: File, docType: string) => {
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      alert("File size must be under 5MB");
      return;
    }

    const preview = file.type.startsWith("image/") ? URL.createObjectURL(file) : undefined;
    const updated = documents.filter((d) => d.type !== docType);
    updated.push({ type: docType, file, preview });
    onChange(updated);
  };

  const handleRemove = (docType: string) => {
    onChange(documents.filter((d) => d.type !== docType));
  };

  const triggerFileInput = (docType: string) => {
    setActiveType(docType);
    setTimeout(() => fileInputRef.current?.click(), 50);
  };

  return (
    <div className="bg-card border border-border rounded-xl p-6 space-y-4">
      <h2 className="text-lg font-semibold mb-2 flex items-center gap-2">
        <FileText className="h-5 w-5 text-primary" />
        {t("booking.uploadDocuments") || "ডকুমেন্ট আপলোড করুন"}
      </h2>
      <p className="text-sm text-muted-foreground mb-4">
        {t("booking.uploadDocumentsDesc") || "আপনার বুকিং সম্পন্ন করতে নিচের ডকুমেন্টগুলো আপলোড করুন। বুকিংয়ের পরেও আপলোড করতে পারবেন।"}
      </p>

      <input
        ref={fileInputRef}
        type="file"
        className="hidden"
        accept="image/*,.pdf"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file && activeType) handleFile(file, activeType);
          e.target.value = "";
        }}
      />

      <div className="space-y-3">
        {DOC_TYPES.map(({ key, labelEn, labelBn }) => {
          const doc = getDocForType(key);
          const label = t(`booking.doc.${key}`) || labelBn;
          return (
            <div
              key={key}
              className={`border rounded-xl p-4 flex items-center justify-between gap-3 transition-all ${
                doc ? "border-primary/30 bg-primary/5" : "border-border hover:border-primary/20"
              }`}
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 ${
                  doc ? "bg-primary/20" : "bg-secondary"
                }`}>
                  {doc ? (
                    <Check className="h-5 w-5 text-primary" />
                  ) : (
                    <Upload className="h-5 w-5 text-muted-foreground" />
                  )}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium">{label}</p>
                  {doc && (
                    <p className="text-xs text-muted-foreground truncate">{doc.file.name}</p>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-2 flex-shrink-0">
                {doc && (
                  <button
                    type="button"
                    onClick={() => handleRemove(key)}
                    className="text-muted-foreground hover:text-destructive transition-colors p-1.5 rounded-md hover:bg-destructive/10"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => triggerFileInput(key)}
                  className="bg-gradient-gold text-primary-foreground text-xs font-semibold px-4 py-2 rounded-lg hover:opacity-90 transition-opacity flex items-center gap-1.5"
                >
                  <Upload className="h-3.5 w-3.5" />
                  {doc ? (t("booking.replace") || "পরিবর্তন") : (t("booking.upload") || "আপলোড")}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      <div className="flex items-start gap-2 p-3 bg-secondary/50 rounded-lg mt-4">
        <AlertCircle className="h-4 w-4 text-muted-foreground mt-0.5 flex-shrink-0" />
        <p className="text-xs text-muted-foreground">
          {t("booking.docNote") || "সর্বোচ্চ ৫MB সাইজের ছবি বা PDF ফাইল আপলোড করুন। এই ধাপ ঐচ্ছিক — আপনি পরেও ডকুমেন্ট জমা দিতে পারবেন।"}
        </p>
      </div>
    </div>
  );
};

export default DocumentUploadStep;
export type { UploadedDoc as DocumentUploadDoc };
