import { Phone, Mail, MapPin, Facebook, Youtube, Instagram, Plane } from "lucide-react";
import sslcommerzPayWith from "@/assets/payment/sslcommerz-pay-with.png";
import logo from "@/assets/triptastic-logo.png";
import { useBulkSiteContent } from "@/hooks/useSiteContentProvider";
import { useLanguage } from "@/i18n/LanguageContext";

const Footer = () => {
  const { data: content } = useBulkSiteContent("footer");
  const { t, language } = useLanguage();

  const lc = content?.[language];
  const companyName = content?.company_name || t("footer.companyName");
  const tagline = lc?.company_tagline || content?.company_tagline || t("footer.tagline");
  const description = lc?.description || content?.description || t("footer.description");
  const phone = content?.phone || "+880 1711-925400";
  const email = content?.email || "info@triptastic.com.bd";
  const address = lc?.address || content?.address || t("footer.address");
  const fallbackServices = [
    t("footer.servicesList.0"),
    t("footer.servicesList.1"),
    t("footer.servicesList.2"),
    t("footer.servicesList.3"),
    t("footer.servicesList.4"),
    t("footer.servicesList.5"),
  ];
  const servicesList = lc?.services_list || content?.services_list || fallbackServices;
  const devName = content?.developer_name || "DigiWebDex";
  const devUrl = content?.developer_url || "https://digiwebdex.com";

  const quickLinks = [
    { label: t("nav.home"), href: "/" },
    { label: t("nav.packages"), href: "/packages" },
    { label: t("nav.hotels"), href: "/hotels" },
    { label: t("nav.about"), href: "/about" },
    { label: t("nav.contact"), href: "/contact" },
    { label: t("nav.track"), href: "/track" },
  ];

  return (
    <>
      {/* CTA Strip — bold gradient */}
      <section className="relative overflow-hidden">
        <div className="bg-gradient-brand py-16 md:py-20 relative">
          <div className="absolute inset-0 travel-pattern opacity-20" />
          <div className="absolute -top-20 -right-20 w-96 h-96 rounded-full bg-primary/40 blur-3xl" />
          <div className="absolute -bottom-20 -left-20 w-96 h-96 rounded-full bg-secondary/50 blur-3xl" />

          <div className="container mx-auto px-4 relative z-10 text-center">
            <Plane className="h-10 w-10 text-white mx-auto mb-4 -rotate-12" />
            <h3 className="text-white font-heading text-3xl md:text-5xl font-extrabold mb-4 drop-shadow-md">
              {language === "bn" ? "আপনার পরবর্তী যাত্রা প্ল্যান করুন" : "Ready for your next adventure?"}
            </h3>
            <p className="text-white/85 text-base md:text-lg max-w-xl mx-auto mb-8">
              {language === "bn"
                ? "আমাদের ট্রাভেল এক্সপার্টদের সাথে কথা বলুন — যেকোনো সার্ভিসের কাস্টমাইজড কোটেশন পান।"
                : "Talk to our travel experts and get a personalised quote for any service."}
            </p>
            <a
              href={`tel:${phone.replace(/[\s-]/g, "")}`}
              className="inline-flex items-center gap-2 bg-white text-secondary font-bold px-8 py-4 rounded-full shadow-elevated hover:scale-105 transition-transform"
            >
              <Phone className="h-4 w-4" />
              {phone}
            </a>
          </div>
        </div>
      </section>

    <footer className="bg-charcoal text-white py-16 relative overflow-hidden">
      {/* Decorative top border */}
      <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-sunset" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10">
          <div className="md:col-span-1">
            <div className="mb-5">
              <div className="bg-white/95 rounded-2xl p-3 inline-block shadow-lg">
                <img
                  src={logo}
                  alt={`${companyName} ${tagline} Logo`}
                  className="h-14 w-auto object-contain"
                />
              </div>
            </div>
            <p className="text-sm leading-relaxed mb-5">
              <span className="text-primary font-semibold italic">{t("footer.quote")}</span>
            </p>
            <div className="flex items-center gap-3">
              <a href={content?.facebook_url || "https://www.facebook.com/profile.php?id=61585173125908"} target="_blank" rel="noopener noreferrer" className="bg-white/8 hover:bg-primary/80 transition-all p-2.5 rounded-xl border border-white/10 hover:border-primary">
                <Facebook className="h-4 w-4 text-white" />
              </a>
              <a href={content?.youtube_url || "#"} target="_blank" rel="noopener noreferrer" className="bg-white/8 hover:bg-red-600/80 transition-all p-2.5 rounded-xl border border-white/10 hover:border-red-600">
                <Youtube className="h-4 w-4 text-white" />
              </a>
              <a href={content?.instagram_url || "#"} target="_blank" rel="noopener noreferrer" className="bg-white/8 hover:bg-pink-600/80 transition-all p-2.5 rounded-xl border border-white/10 hover:border-pink-600">
                <Instagram className="h-4 w-4 text-white" />
              </a>
            </div>
          </div>

          <div>
            <h4 className="font-heading font-semibold mb-5 text-primary text-sm uppercase tracking-wider">{t("footer.quickLinks")}</h4>
            <ul className="space-y-3 text-sm text-white/50">
              {quickLinks.map((l) => (
                <li key={l.href}>
                  <a href={l.href} className="hover:text-primary transition-colors">{l.label}</a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-heading font-semibold mb-5 text-primary text-sm uppercase tracking-wider">{t("footer.services")}</h4>
            <ul className="space-y-3 text-sm text-white/50">
              {servicesList.map((s: string) => (
                <li key={s}><span>{s}</span></li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-heading font-semibold mb-5 text-primary text-sm uppercase tracking-wider">{t("footer.contact")}</h4>
            <ul className="space-y-4 text-sm text-white/50">
              <li className="flex items-start gap-3"><div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center flex-shrink-0 mt-0.5"><Phone className="h-3.5 w-3.5 text-primary" /></div> <span>{phone}</span></li>
              <li className="flex items-center gap-3"><div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center flex-shrink-0"><Mail className="h-3.5 w-3.5 text-primary" /></div> {email}</li>
              <li className="flex items-start gap-3"><div className="w-8 h-8 rounded-lg bg-primary/15 flex items-center justify-center flex-shrink-0 mt-0.5"><MapPin className="h-3.5 w-3.5 text-primary" /></div> <span className="whitespace-pre-line">{address}</span></li>
            </ul>
          </div>
        </div>

        <div className="mt-14 pt-8 border-t border-white/8">
          <div className="flex flex-wrap justify-center gap-4 mb-6 text-sm text-white/40">
            <a href="/privacy-policy" className="hover:text-primary transition-colors">{t("footer.privacyPolicy")}</a>
            <span className="text-white/15">|</span>
            <a href="/terms-conditions" className="hover:text-primary transition-colors">{t("footer.termsConditions")}</a>
            <span className="text-white/15">|</span>
            <a href="/refund-policy" className="hover:text-primary transition-colors">{t("footer.refundPolicy")}</a>
          </div>
          <div className="flex justify-center mb-5">
            <img src={sslcommerzPayWith} alt="Payment Methods - Pay With SSLCommerz" className="h-10 md:h-12 object-contain opacity-60" />
          </div>
          <div className="text-center text-sm text-white/35">
            <p>© {new Date().getFullYear()} {companyName} {tagline}. {t("footer.allRights")}</p>
            <p className="mt-2 text-xs text-white/30">
              {language === "bn" ? "ট্রেড লাইসেন্স নং" : "Trade License No"}: <span className="text-white/60 font-medium">77349852504677</span>
            </p>
            <p className="mt-2 text-xs text-white/20">{t("footer.designBy")} <a href={devUrl} target="_blank" rel="noopener noreferrer" className="hover:text-primary transition-colors">{devName}</a></p>
          </div>
        </div>
      </div>
    </footer>
    </>
  );
};

export default Footer;
