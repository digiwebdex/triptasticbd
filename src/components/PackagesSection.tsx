import { motion } from "framer-motion";
import { ArrowRight, Clock, Star, Plane, Check } from "lucide-react";
import { useNavigate } from "react-router-dom";
import BookingDialog from "@/components/BookingDialog";
import { useState } from "react";
import { useLanguage } from "@/i18n/LanguageContext";
import heroImage from "@/assets/hero-kaaba-golden.jpg";
import medinaImage from "@/assets/hero-medina.jpg";
import { useActivePackages } from "@/hooks/usePackagesData";

const fallbackImages = [heroImage, medinaImage];

const TYPE_ORDER = ["hajj", "umrah", "tour", "visa", "air_ticket", "hotel", "transport", "ziyara"];
const TYPE_LABELS: Record<string, { en: string; bn: string }> = {
  hajj: { en: "Hajj Packages", bn: "হজ্জ প্যাকেজ" },
  umrah: { en: "Umrah Packages", bn: "উমরাহ প্যাকেজ" },
  tour: { en: "Tour Packages", bn: "ট্যুর প্যাকেজ" },
  visa: { en: "Visa Services", bn: "ভিসা সার্ভিস" },
  air_ticket: { en: "Air Tickets", bn: "এয়ার টিকেট" },
  hotel: { en: "Hotel Packages", bn: "হোটেল প্যাকেজ" },
  transport: { en: "Transport Packages", bn: "পরিবহন প্যাকেজ" },
  ziyara: { en: "Ziyara Packages", bn: "জিয়ারত প্যাকেজ" },
};

const PackagesSection = () => {
  const { t, language } = useLanguage();
  const navigate = useNavigate();
  const { data: packages = [], isLoading: loading } = useActivePackages();
  const [bookingPackageId, setBookingPackageId] = useState<string | null>(null);
  const [bookingOpen, setBookingOpen] = useState(false);

  if (loading || packages.length === 0) return null;

  const grouped = packages.reduce((acc: Record<string, any[]>, pkg) => {
    const type = pkg.type || "other";
    if (!acc[type]) acc[type] = [];
    acc[type].push(pkg);
    return acc;
  }, {});

  const sortedTypes = Object.keys(grouped).sort((a, b) => {
    const ai = TYPE_ORDER.indexOf(a);
    const bi = TYPE_ORDER.indexOf(b);
    return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
  });

  return (
    <section id="packages" className="py-24 bg-secondary/30 relative overflow-hidden">
      <div className="absolute inset-0 islamic-pattern opacity-30" />
      
      <div className="container mx-auto px-4 relative z-10">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
          <span className="text-primary text-xs font-semibold tracking-[0.3em] uppercase">{t("packages.label")}</span>
          <h2 className="font-heading text-3xl md:text-5xl font-bold mt-3 mb-4">
            {t("packages.heading")} <span className="text-gradient-gold">{t("packages.headingHighlight")}</span>
          </h2>
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="h-px w-12 bg-primary/30" />
            <div className="w-2 h-2 rounded-full bg-primary/50" />
            <div className="h-px w-12 bg-primary/30" />
          </div>
          <p className="text-muted-foreground max-w-xl mx-auto">{t("packages.description")}</p>
        </motion.div>

        {sortedTypes.map((type) => {
          const typePkgs = grouped[type];
          const label = TYPE_LABELS[type]?.[language] || `${type.charAt(0).toUpperCase() + type.slice(1)} Packages`;

          return (
            <div key={type} className="mb-16 last:mb-0">
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                className="flex items-center gap-3 mb-8"
              >
                <div className="h-8 w-1.5 rounded-full bg-gradient-gold" />
                <h3 className="font-heading text-2xl md:text-3xl font-bold capitalize">{label}</h3>
                <span className="text-xs bg-primary/10 text-primary px-3 py-1 rounded-full font-medium">
                  {typePkgs.length} {t("common.packagesSuffix")}
                </span>
              </motion.div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-7 max-w-6xl mx-auto">
                {typePkgs.map((pkg: any, i: number) => {
                  const features = Array.isArray(pkg.features) ? pkg.features : [];
                  const services = Array.isArray(pkg.services) ? pkg.services : [];
                  const hasFeatures = features.length > 0;

                  return (
                    <motion.div
                      key={pkg.id}
                      initial={{ opacity: 0, y: 30 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: i * 0.1 }}
                      className="relative rounded-2xl overflow-hidden bg-card border border-border flex flex-col group hover:shadow-elevated transition-all duration-500"
                    >
                      {/* Image with fixed 16:9 ratio and bullet points overlay */}
                      <div className="relative overflow-hidden" style={{ aspectRatio: "16/9" }}>
                        <img
                          src={pkg.image_url || fallbackImages[i % fallbackImages.length]}
                          alt={pkg.name}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                          loading="lazy"
                        />
                        <div className="absolute inset-0 bg-gradient-to-t from-[hsl(220,25%,10%)]/80 via-[hsl(220,25%,10%)]/30 to-transparent" />

                        {/* Type badge */}
                        <div className="absolute top-3 left-3">
                          <span className="bg-primary text-primary-foreground text-[11px] font-bold px-3 py-1.5 rounded-full capitalize shadow-md">
                            {pkg.type}
                          </span>
                        </div>

                        {/* Rating */}
                        <div className="absolute top-3 right-3 flex items-center gap-1 bg-white/90 backdrop-blur-sm px-2.5 py-1 rounded-full">
                          <Star className="h-3 w-3 fill-primary text-primary" />
                          <span className="text-xs font-bold text-foreground">4.9</span>
                        </div>

                        {/* Bullet points overlay on image */}
                        {hasFeatures && (
                          <div className="absolute top-12 left-3 right-3">
                            <ul className="space-y-1">
                              {features.slice(0, 7).map((f: string, fi: number) => (
                                <li key={fi} className="flex items-start gap-1.5 text-[11px] leading-tight text-white drop-shadow-md">
                                  <span className="text-primary font-bold flex-shrink-0">►</span>
                                  <span className="line-clamp-1">{f}</span>
                                </li>
                              ))}
                            </ul>
                          </div>
                        )}

                        {/* Price at bottom */}
                        <div className="absolute bottom-3 left-3">
                          <p className="text-2xl font-heading font-bold text-white drop-shadow-lg">
                            ৳{Number(pkg.price).toLocaleString("en-IN")}
                          </p>
                          <p className="text-[11px] text-white/80">/ {t("packages.perPerson")}</p>
                        </div>

                        {/* Services tags at bottom right */}
                        {services.length > 0 && (
                          <div className="absolute bottom-3 right-3 flex flex-wrap gap-1 justify-end max-w-[60%]">
                            {services.slice(0, 3).map((s: string, si: number) => (
                              <span key={si} className="text-[9px] bg-primary/80 text-white px-2 py-0.5 rounded-full font-medium backdrop-blur-sm">
                                {s}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>

                      {/* Card body */}
                      <div className="p-5 flex-1 flex flex-col">
                        <h3 className="font-heading text-lg font-bold mb-2 line-clamp-1">{pkg.name}</h3>
                        <div className="flex items-center gap-4 mb-3 text-xs text-muted-foreground">
                          {pkg.duration_days && (
                            <span className="flex items-center gap-1">
                              <Clock className="h-3.5 w-3.5" />
                              {pkg.duration_days} {t("common.days")}
                            </span>
                          )}
                          {services.length > 0 && (
                            <span className="flex items-center gap-1">
                              <Plane className="h-3.5 w-3.5" />
                              {services[0]}
                            </span>
                          )}
                        </div>
                        {pkg.description && (
                          <p className="text-sm text-muted-foreground line-clamp-2 mb-4 flex-1">{pkg.description}</p>
                        )}
                        <button
                          onClick={() => { setBookingPackageId(pkg.id); setBookingOpen(true); }}
                          className="w-full py-3 rounded-xl text-sm font-semibold text-center inline-flex items-center justify-center gap-2 bg-gradient-gold text-primary-foreground hover:opacity-90 hover:shadow-gold transition-all duration-300 cursor-pointer mt-auto"
                        >
                          {t("packages.bookNow")} <ArrowRight className="h-4 w-4" />
                        </button>
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            </div>
          );
        })}

        <div className="text-center mt-10">
          <button
            onClick={() => navigate("/packages")}
            className="text-primary hover:underline text-sm font-medium inline-flex items-center gap-1"
          >
            {t("common.viewAll")} <ArrowRight className="h-4 w-4" />
          </button>
        </div>
      </div>

      <BookingDialog open={bookingOpen} onOpenChange={setBookingOpen} packageId={bookingPackageId} />
    </section>
  );
};

export default PackagesSection;
