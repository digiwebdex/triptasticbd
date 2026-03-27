import { Phone, Mail, MapPin, Facebook, Youtube, Instagram } from "lucide-react";
import sslcommerzPayWith from "@/assets/payment/sslcommerz-pay-with.png";
import logo from "@/assets/logo.png";
import { useSiteContent } from "@/hooks/useSiteContent";
import { useLanguage } from "@/i18n/LanguageContext";

const Footer = () => {
  const { data: content } = useSiteContent("footer");
  const { t, language } = useLanguage();

  const lc = content?.[language];
  const companyName = content?.company_name || "MANASIK";
  const tagline = lc?.company_tagline || (language === "bn" ? "ট্রাভেল হাব" : content?.company_tagline || "Travel Hub");
  const description = lc?.description || (language === "bn" ? "হজ্জ ও উমরাহের বিশ্বস্ত সঙ্গী। পবিত্র যাত্রা সহজ করে আসছি।" : content?.description || "Your trusted companion for Hajj & Umrah. Making sacred journeys easy and comfortable.");
  const phone = content?.phone || "+880 1711-993562";
  const email = content?.email || "manasiktravelhub@gmail.com";
  const address = lc?.address || (language === "bn" ? "৫৯৫/১, মিল্ক ভিটা রোড, তিন রাস্তার মোড়\nদেওলা, টাঙ্গাইল সদর, টাঙ্গাইল" : content?.address || "595/1, Milk Vita Road, Three-way Intersection\nDewla, Tangail Sadar, Tangail");
  const servicesList = lc?.services_list || (language === "bn" ? ["হজ প্যাকেজ", "উমরাহ প্যাকেজ", "ভিসা প্রসেসিং", "এয়ার টিকেট", "হোটেল বুকিং", "জিয়ারা ট্যুর"] : content?.services_list || ["Hajj Packages", "Umrah Packages", "Visa Processing", "Air Tickets", "Hotel Booking", "Ziyara Tours"]);
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
    <footer className="bg-charcoal text-white py-16">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10">
          <div className="md:col-span-1">
            <div className="flex items-center gap-3 mb-4">
              <img src={logo} alt={`${companyName} Logo`} className="h-12 w-auto object-contain" />
              <div>
                <span className="font-heading text-lg font-bold text-primary">{companyName}</span>
                <span className="block text-xs tracking-[0.2em] text-muted-foreground uppercase">{tagline}</span>
              </div>
            </div>
            <p className="text-sm text-white/60 leading-relaxed mb-4">{description}</p>
            <div className="flex items-center gap-3">
              <a href={content?.facebook_url || "https://www.facebook.com/profile.php?id=61585173125908"} target="_blank" rel="noopener noreferrer" className="bg-white/10 hover:bg-primary/80 transition-colors p-2 rounded-full">
                <Facebook className="h-4 w-4 text-white" />
              </a>
              <a href={content?.youtube_url || "#"} target="_blank" rel="noopener noreferrer" className="bg-white/10 hover:bg-red-600/80 transition-colors p-2 rounded-full">
                <Youtube className="h-4 w-4 text-white" />
              </a>
              <a href={content?.instagram_url || "#"} target="_blank" rel="noopener noreferrer" className="bg-white/10 hover:bg-pink-600/80 transition-colors p-2 rounded-full">
                <Instagram className="h-4 w-4 text-white" />
              </a>
            </div>
          </div>

          <div>
            <h4 className="font-heading font-semibold mb-4 text-gold-light">{t("footer.quickLinks")}</h4>
            <ul className="space-y-2.5 text-sm text-white/60">
              {quickLinks.map((l) => (
                <li key={l.href}>
                  <a href={l.href} className="hover:text-gold-light transition-colors">{l.label}</a>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-heading font-semibold mb-4 text-gold-light">{t("footer.services")}</h4>
            <ul className="space-y-2.5 text-sm text-white/60">
              {servicesList.map((s: string) => (
                <li key={s}><span>{s}</span></li>
              ))}
            </ul>
          </div>

          <div>
            <h4 className="font-heading font-semibold mb-4 text-gold-light">{t("footer.contact")}</h4>
            <ul className="space-y-3 text-sm text-white/60">
              <li className="flex items-center gap-2"><Phone className="h-4 w-4 text-gold-light" /> {phone}</li>
              <li className="flex items-center gap-2"><Mail className="h-4 w-4 text-gold-light" /> {email}</li>
              <li className="flex items-start gap-2"><MapPin className="h-4 w-4 text-gold-light mt-0.5" /> <span className="whitespace-pre-line">{address}</span></li>
            </ul>
          </div>
        </div>

        <div className="mt-12 pt-8 border-t border-white/10">
          <div className="flex flex-wrap justify-center gap-4 mb-6 text-sm text-white/60">
            <a href="/privacy-policy" className="hover:text-gold-light transition-colors">{language === "bn" ? "গোপনীয়তা নীতি" : "Privacy Policy"}</a>
            <span className="text-white/20">|</span>
            <a href="/terms-conditions" className="hover:text-gold-light transition-colors">{language === "bn" ? "শর্তাবলী" : "Terms & Conditions"}</a>
            <span className="text-white/20">|</span>
            <a href="/refund-policy" className="hover:text-gold-light transition-colors">{language === "bn" ? "রিফান্ড নীতি" : "Refund Policy"}</a>
          </div>
          <div className="flex justify-center mb-4">
            <img src={sslcommerzPayWith} alt="Payment Methods - Pay With SSLCommerz" className="h-10 md:h-12 object-contain opacity-80" />
          </div>
          <div className="text-center text-sm text-white/50">
            <p>© {new Date().getFullYear()} {companyName} {tagline}. {t("footer.allRights")}</p>
            <p className="mt-2 text-xs text-white/30">{t("footer.designBy")} <a href={devUrl} target="_blank" rel="noopener noreferrer" className="hover:text-gold-light transition-colors">{devName}</a></p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
