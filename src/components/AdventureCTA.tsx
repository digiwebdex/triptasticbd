import { motion } from "framer-motion";
import { Plane, MapPin, Sparkles, Globe2, Star, Heart, Compass, Camera } from "lucide-react";
import { useLanguage } from "@/i18n/LanguageContext";

const AdventureCTA = () => {
  const { language } = useLanguage();
  const isBn = language === "bn";

  const destinations = [
    { name: isBn ? "মক্কা" : "Makkah", emoji: "🕋", color: "from-amber-400 to-orange-500", delay: 0 },
    { name: isBn ? "মদিনা" : "Madinah", emoji: "🌙", color: "from-emerald-400 to-teal-500", delay: 0.1 },
    { name: isBn ? "দুবাই" : "Dubai", emoji: "🏙️", color: "from-sky-400 to-blue-500", delay: 0.2 },
    { name: isBn ? "ইস্তাম্বুল" : "Istanbul", emoji: "🕌", color: "from-rose-400 to-pink-500", delay: 0.3 },
    { name: isBn ? "মালয়েশিয়া" : "Malaysia", emoji: "🌴", color: "from-lime-400 to-green-500", delay: 0.4 },
    { name: isBn ? "সিঙ্গাপুর" : "Singapore", emoji: "🦁", color: "from-fuchsia-400 to-purple-500", delay: 0.5 },
    { name: isBn ? "তুরস্ক" : "Turkey", emoji: "🎈", color: "from-red-400 to-rose-500", delay: 0.6 },
    { name: isBn ? "জাপান" : "Japan", emoji: "🗼", color: "from-pink-400 to-red-500", delay: 0.7 },
  ];

  const stats = [
    { icon: Globe2, value: "25+", label: isBn ? "গন্তব্য" : "Destinations" },
    { icon: Heart, value: "10K+", label: isBn ? "খুশি যাত্রী" : "Happy Travelers" },
    { icon: Star, value: "4.9", label: isBn ? "রেটিং" : "Rating" },
    { icon: Compass, value: "12+", label: isBn ? "বছরের অভিজ্ঞতা" : "Years Experience" },
  ];

  return (
    <div className="relative w-full max-w-6xl mx-auto">
      {/* Floating decorative icons */}
      <motion.div
        className="absolute -top-8 left-[10%] text-white/30 hidden md:block"
        animate={{ y: [0, -15, 0], rotate: [0, 10, 0] }}
        transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
      >
        <Plane className="h-8 w-8 -rotate-45" />
      </motion.div>
      <motion.div
        className="absolute -top-4 right-[8%] text-white/30 hidden md:block"
        animate={{ y: [0, -20, 0], rotate: [0, -15, 0] }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut", delay: 1 }}
      >
        <Camera className="h-7 w-7" />
      </motion.div>
      <motion.div
        className="absolute top-1/3 left-[3%] text-white/25 hidden lg:block"
        animate={{ y: [0, 12, 0], scale: [1, 1.1, 1] }}
        transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
      >
        <Sparkles className="h-6 w-6" />
      </motion.div>
      <motion.div
        className="absolute top-1/2 right-[4%] text-white/25 hidden lg:block"
        animate={{ y: [0, -10, 0], rotate: [0, 360] }}
        transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
      >
        <Compass className="h-7 w-7" />
      </motion.div>

      {/* Destination cards floating circle */}
      <div className="relative grid grid-cols-2 sm:grid-cols-4 gap-3 md:gap-5 mb-10">
        {destinations.map((dest, i) => (
          <motion.div
            key={dest.name}
            initial={{ opacity: 0, y: 30, scale: 0.8 }}
            whileInView={{ opacity: 1, y: 0, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: dest.delay, type: "spring", stiffness: 120 }}
            whileHover={{ y: -8, scale: 1.05 }}
            className="group relative cursor-pointer"
          >
            {/* Floating animation wrapper */}
            <motion.div
              animate={{ y: [0, -6, 0] }}
              transition={{
                duration: 3 + i * 0.2,
                repeat: Infinity,
                ease: "easeInOut",
                delay: i * 0.15,
              }}
              className="relative"
            >
              {/* Glow */}
              <div className={`absolute inset-0 bg-gradient-to-br ${dest.color} rounded-2xl blur-xl opacity-40 group-hover:opacity-70 transition-opacity`} />

              {/* Card */}
              <div className="relative bg-white/10 backdrop-blur-md border border-white/25 rounded-2xl p-4 md:p-5 overflow-hidden">
                {/* Shine sweep */}
                <motion.div
                  className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -skew-x-12"
                  initial={{ x: "-150%" }}
                  animate={{ x: "150%" }}
                  transition={{
                    duration: 2.5,
                    repeat: Infinity,
                    repeatDelay: 4 + i * 0.5,
                    ease: "easeInOut",
                  }}
                />
                <div className="relative flex flex-col items-center text-center gap-2">
                  <div className={`text-3xl md:text-4xl drop-shadow-lg`}>{dest.emoji}</div>
                  <div className="text-white text-xs md:text-sm font-bold tracking-wide">
                    {dest.name}
                  </div>
                  <div className="flex items-center gap-1 text-white/70 text-[10px]">
                    <MapPin className="h-2.5 w-2.5" />
                    <span>{isBn ? "জনপ্রিয়" : "Popular"}</span>
                  </div>
                </div>
              </div>
            </motion.div>
          </motion.div>
        ))}
      </div>

      {/* Stats strip */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6, delay: 0.4 }}
        className="grid grid-cols-2 md:grid-cols-4 gap-3 md:gap-4 max-w-4xl mx-auto"
      >
        {stats.map((stat, i) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={stat.label}
              whileHover={{ y: -4, scale: 1.03 }}
              className="relative bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl px-4 py-4 flex items-center gap-3 overflow-hidden group"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="relative w-10 h-10 rounded-xl bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center shadow-lg shadow-amber-500/30">
                <Icon className="h-5 w-5 text-white" />
              </div>
              <div className="relative text-left">
                <div className="text-white font-extrabold text-xl md:text-2xl leading-none tabular-nums">
                  {stat.value}
                </div>
                <div className="text-white/70 text-[11px] md:text-xs mt-0.5">{stat.label}</div>
              </div>
            </motion.div>
          );
        })}
      </motion.div>
    </div>
  );
};

export default AdventureCTA;
