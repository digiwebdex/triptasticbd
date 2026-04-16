import { MessageCircle } from "lucide-react";
import { useBulkSiteContent } from "@/hooks/useSiteContentProvider";
import { useLanguage } from "@/i18n/LanguageContext";

const WhatsAppFloat = () => {
  const { data: content } = useBulkSiteContent("whatsapp");
  const { t, language } = useLanguage();
  const lc = content?.[language];

  const phone = content?.phone || "8801711999910";
  const message = encodeURIComponent(lc?.message || t("whatsapp.message"));
  const buttonText = lc?.button_text || t("whatsapp.button");

  return (
    <a
      href={`https://wa.me/${phone}?text=${message}`}
      target="_blank"
      rel="noopener noreferrer"
      className="fixed bottom-6 left-6 z-50 flex items-center gap-2.5 bg-[#25D366] hover:bg-[#1ebe57] text-white pl-4 pr-5 py-3 rounded-full shadow-lg hover:shadow-xl transition-all duration-300 group"
      aria-label="Chat on WhatsApp"
    >
      <MessageCircle className="h-6 w-6 fill-white stroke-white flex-shrink-0" />
      <span className="text-sm font-medium hidden sm:inline whitespace-nowrap">
        {buttonText}
      </span>
    </a>
  );
};

export default WhatsAppFloat;
