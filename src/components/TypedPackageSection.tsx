import { useMemo } from "react";
import { motion } from "framer-motion";
import { ArrowRight, Plane, FileText, Map } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useLanguage } from "@/i18n/LanguageContext";
import { useActivePackages } from "@/hooks/usePackagesData";
import PackageCard from "@/components/PackageCard";

const TYPE_CONFIG: Record<string, {
  en: { label: string; heading: string; highlight: string; description: string };
  bn: { label: string; heading: string; highlight: string; description: string };
  icon: any;
  gradient: string;
}> = {
  air_ticket: {
    en: { label: "Air Travel", heading: "Book Your", highlight: "Air Tickets", description: "Best-price airline tickets with flexible booking options for domestic and international travel" },
    bn: { label: "বিমান ভ্রমণ", heading: "বুক করুন আপনার", highlight: "এয়ার টিকেট", description: "দেশীয় এবং আন্তর্জাতিক ভ্রমণের জন্য সেরা মূল্যে বিমান টিকেট" },
    icon: Plane, gradient: "from-blue-500 to-cyan-500",
  },
  visa: {
    en: { label: "Visa Services", heading: "Hassle-Free", highlight: "Visa Processing", description: "Expert visa processing services for Saudi Arabia and other destinations worldwide" },
    bn: { label: "ভিসা সেবা", heading: "ঝামেলামুক্ত", highlight: "ভিসা প্রসেসিং", description: "সৌদি আরব এবং বিশ্বব্যাপী অন্যান্য গন্তব্যের জন্য বিশেষজ্ঞ ভিসা সেবা" },
    icon: FileText, gradient: "from-emerald-500 to-teal-500",
  },
  tour: {
    en: { label: "Tour Packages", heading: "Explore Amazing", highlight: "Tour Packages", description: "Discover exciting destinations with our carefully curated tour packages" },
    bn: { label: "ট্যুর প্যাকেজ", heading: "দেখুন আকর্ষণীয়", highlight: "ট্যুর প্যাকেজ", description: "আমাদের যত্নসহকারে তৈরি ট্যুর প্যাকেজ দিয়ে উত্তেজনাপূর্ণ গন্তব্য আবিষ্কার করুন" },
    icon: Map, gradient: "from-orange-500 to-amber-500",
  },
};

interface TypedPackageSectionProps {
  packageType: string;
  sectionId: string;
}

const TypedPackageSection = ({ packageType, sectionId }: TypedPackageSectionProps) => {
  const { t, language } = useLanguage();
  const navigate = useNavigate();
  const { data: allPackages = [], isLoading: loading } = useActivePackages();

  const packages = useMemo(
    () => allPackages.filter((p: any) => p.type === packageType),
    [allPackages, packageType]
  );

  if (loading || packages.length === 0) return null;

  const config = TYPE_CONFIG[packageType];
  if (!config) return null;

  const loc = config[language] || config.en;
  const IconComp = config.icon;

  return (
    <section id={sectionId} className="py-24 bg-secondary/30 islamic-border-top">
      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="text-primary text-sm font-medium tracking-[0.3em] uppercase inline-flex items-center gap-2">
            <IconComp className="h-4 w-4" />
            {loc.label}
          </span>
          <h2 className="font-heading text-3xl md:text-5xl font-bold mt-3 mb-4">
            {loc.heading}{" "}
            <span className="text-gradient-gold">{loc.highlight}</span>
          </h2>
          <p className="text-muted-foreground max-w-xl mx-auto">{loc.description}</p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {packages.slice(0, 6).map((pkg: any, i: number) => (
            <PackageCard key={pkg.id} pkg={pkg} index={i} />
          ))}
        </div>

        {packages.length > 6 && (
          <div className="text-center mt-10">
            <button
              onClick={() => navigate(`/packages?type=${packageType}`)}
              className="text-primary hover:underline text-sm font-medium inline-flex items-center gap-1"
            >
              {t("common.viewAll") || "View All"} <ArrowRight className="h-4 w-4" />
            </button>
          </div>
        )}
      </div>
    </section>
  );
};

export default TypedPackageSection;
