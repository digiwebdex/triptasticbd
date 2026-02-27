import { motion } from "framer-motion";
import { Check, ArrowRight } from "lucide-react";
import heroImage from "@/assets/hero-kaaba.jpg";
import medinaImage from "@/assets/medina-mosque.jpg";
import { useLanguage } from "@/i18n/LanguageContext";

const PackagesSection = () => {
  const { t, language } = useLanguage();
  const bn = language === "bn";

  const packages = [
    {
      name: bn ? "রমজান প্যাকেজ" : "Ramadan Package",
      price: "",
      duration: bn ? "১৭ ফেব্রুয়ারি ২০২৬" : "17 February 2026",
      image: heroImage,
      popular: false,
      features: bn
        ? ["রিটার্ন এয়ার টিকেট", "হোটেল বুকিং", "ভিসা প্রসেসিং", "গ্রাউন্ড ট্রান্সপোর্ট", "জিয়ারা ট্যুর", "খাবার অন্তর্ভুক্ত"]
        : ["Return Air Ticket", "Hotel Booking", "Visa Processing", "Ground Transport", "Ziyara Tour", "Meals Included"],
    },
    {
      name: bn ? "এতেকাফ প্যাকেজ" : "Etekaf Package",
      price: "",
      duration: bn ? "৭ মার্চ ২০২৬" : "7 March 2026",
      image: medinaImage,
      popular: true,
      features: bn
        ? ["রিটার্ন এয়ার টিকেট", "হারামের নিকটে হোটেল", "ভিসা প্রসেসিং", "ভিআইপি ট্রান্সপোর্ট", "সম্পূর্ণ জিয়ারা", "সব খাবার", "ব্যক্তিগত গাইড"]
        : ["Return Air Ticket", "Hotel Near Haram", "Visa Processing", "VIP Transport", "Full Ziyara", "All Meals", "Personal Guide"],
    },
    {
      name: bn ? "ঈদ পরবর্তী প্যাকেজ" : "Post-Eid Package",
      price: "",
      duration: bn ? "২৩ মার্চ ২০২৬" : "23 March 2026",
      image: heroImage,
      popular: false,
      features: bn
        ? ["রিটার্ন এয়ার টিকেট", "প্রিমিয়াম থাকার ব্যবস্থা", "ভিসা প্রসেসিং", "সম্পূর্ণ পরিবহন", "সম্পূর্ণ জিয়ারা", "সব খাবার", "অভিজ্ঞ গাইড"]
        : ["Return Air Ticket", "Premium Accommodation", "Visa Processing", "Full Transport", "Complete Ziyara", "All Meals", "Experienced Guide"],
    },
  ];

  return (
    <section id="packages" className="py-24 bg-card">
      <div className="container mx-auto px-4">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
          <span className="text-primary text-sm font-medium tracking-[0.3em] uppercase">{t("packages.label")}</span>
          <h2 className="font-heading text-3xl md:text-5xl font-bold mt-3 mb-4">
            {t("packages.heading")} <span className="text-gradient-gold">{t("packages.headingHighlight")}</span>
          </h2>
          <p className="text-muted-foreground max-w-xl mx-auto">{t("packages.description")}</p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {packages.map((pkg, i) => (
            <motion.div key={pkg.name} initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.15 }}
              className={`relative rounded-xl overflow-hidden border ${pkg.popular ? "border-primary shadow-gold scale-[1.03]" : "border-border"} bg-background flex flex-col`}>
              {pkg.popular && (
                <div className="absolute top-4 right-4 z-10 bg-gradient-gold text-primary-foreground text-xs font-bold px-3 py-1 rounded-full">
                  {t("packages.mostPopular")}
                </div>
              )}
              <div className="h-48 overflow-hidden">
                <img src={pkg.image} alt={pkg.name} className="w-full h-full object-cover" />
                <div className="absolute top-0 left-0 right-0 h-48 bg-gradient-to-b from-transparent to-background/80" />
              </div>
              <div className="p-6 flex-1 flex flex-col">
                <h3 className="font-heading text-xl font-bold">{pkg.name}</h3>
                <p className="text-sm text-muted-foreground mb-4">{pkg.duration}</p>
                {pkg.price && (
                  <p className="text-3xl font-heading font-bold text-primary mb-6">
                    {pkg.price}
                    <span className="text-sm font-body text-muted-foreground font-normal"> {t("packages.perPerson")}</span>
                  </p>
                )}
                <ul className="space-y-2.5 mb-6 flex-1">
                  {pkg.features.map((f) => (
                    <li key={f} className="flex items-center gap-2 text-sm text-foreground/80">
                      <Check className="h-4 w-4 text-primary flex-shrink-0" />{f}
                    </li>
                  ))}
                </ul>
                <a href="#contact" className={`w-full py-3 rounded-md text-sm font-semibold text-center inline-flex items-center justify-center gap-2 transition-all ${pkg.popular ? "bg-gradient-gold text-primary-foreground hover:opacity-90" : "border border-primary/40 text-foreground hover:bg-primary/10"}`}>
                  {t("packages.bookNow")} <ArrowRight className="h-4 w-4" />
                </a>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default PackagesSection;
