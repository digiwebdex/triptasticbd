import { motion } from "framer-motion";
import { useLanguage } from "@/i18n/LanguageContext";

// Origin = Bangladesh; destinations = popular travel hubs
const ORIGIN = { x: 760, y: 230, label: "Bangladesh", labelBn: "বাংলাদেশ", sub: "ORIGIN HUB" };
const DESTINATIONS = [
  { x: 555, y: 180, label: "Saudi Arabia", labelBn: "সৌদি আরব", flag: "🇸🇦" },
  { x: 600, y: 220, label: "UAE", labelBn: "সংযুক্ত আরব আমিরাত", flag: "🇦🇪" },
  { x: 530, y: 160, label: "Turkey", labelBn: "তুরস্ক", flag: "🇹🇷" },
  { x: 820, y: 260, label: "Malaysia", labelBn: "মালয়েশিয়া", flag: "🇲🇾" },
  { x: 870, y: 290, label: "Singapore", labelBn: "সিঙ্গাপুর", flag: "🇸🇬" },
  { x: 470, y: 130, label: "UK", labelBn: "যুক্তরাজ্য", flag: "🇬🇧" },
  { x: 280, y: 130, label: "Canada", labelBn: "কানাডা", flag: "🇨🇦" },
  { x: 920, y: 180, label: "Japan", labelBn: "জাপান", flag: "🇯🇵" },
];

// Generate dot grid pattern (shaped like world landmass roughly)
const generateMapDots = () => {
  const dots: { x: number; y: number }[] = [];
  for (let y = 80; y < 380; y += 12) {
    for (let x = 100; x < 1000; x += 12) {
      // Rough landmass mask via sin functions to feel like continents
      const noise =
        Math.sin(x * 0.02) * Math.cos(y * 0.03) +
        Math.sin((x + y) * 0.018) * 0.6 +
        Math.cos(x * 0.012 + y * 0.02) * 0.4;
      const distFromCenter = Math.abs(y - 220) / 200;
      if (noise > -0.15 && distFromCenter < 1.1 && Math.random() > 0.25) {
        dots.push({ x, y });
      }
    }
  }
  return dots;
};

const MAP_DOTS = generateMapDots();

// Build an SVG quadratic curve path between two points
const curvePath = (x1: number, y1: number, x2: number, y2: number) => {
  const mx = (x1 + x2) / 2;
  const my = (y1 + y2) / 2 - Math.abs(x2 - x1) * 0.18 - 20;
  return `M ${x1} ${y1} Q ${mx} ${my} ${x2} ${y2}`;
};

const AnimatedWorldMap = () => {
  const { language } = useLanguage();

  return (
    <div className="relative w-full max-w-5xl mx-auto">
      {/* Top status pill */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="absolute top-2 left-2 md:top-4 md:left-4 z-20 flex items-center gap-2 bg-white/10 backdrop-blur-md border border-white/20 px-3 py-1.5 rounded-full text-[10px] md:text-xs text-white font-semibold tracking-wider uppercase"
      >
        <span className="relative flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75" />
          <span className="relative inline-flex rounded-full h-2 w-2 bg-primary" />
        </span>
        TRIP TASTIC • {DESTINATIONS.length} {language === "bn" ? "একটিভ রুট" : "ACTIVE ROUTES"}
      </motion.div>

      <svg
        viewBox="0 0 1100 440"
        className="w-full h-auto"
        style={{ filter: "drop-shadow(0 10px 40px rgba(0,0,0,0.3))" }}
      >
        <defs>
          <linearGradient id="routeGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="hsl(38, 90%, 60%)" stopOpacity="0.1" />
            <stop offset="50%" stopColor="hsl(38, 90%, 60%)" stopOpacity="0.9" />
            <stop offset="100%" stopColor="hsl(38, 90%, 60%)" stopOpacity="0.4" />
          </linearGradient>
          <radialGradient id="hubGlow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="hsl(38, 95%, 60%)" stopOpacity="0.7" />
            <stop offset="50%" stopColor="hsl(38, 95%, 60%)" stopOpacity="0.2" />
            <stop offset="100%" stopColor="hsl(38, 95%, 60%)" stopOpacity="0" />
          </radialGradient>
          <filter id="glow">
            <feGaussianBlur stdDeviation="3" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Map dotted background */}
        <g opacity="0.45">
          {MAP_DOTS.map((d, i) => (
            <circle
              key={i}
              cx={d.x}
              cy={d.y}
              r="1.4"
              fill="hsl(188, 60%, 55%)"
            />
          ))}
        </g>

        {/* Route lines with animated dash */}
        {DESTINATIONS.map((dest, i) => {
          const path = curvePath(ORIGIN.x, ORIGIN.y, dest.x, dest.y);
          return (
            <g key={`route-${i}`}>
              {/* Static faint base line */}
              <path
                d={path}
                stroke="hsl(38, 90%, 60%)"
                strokeWidth="1"
                strokeDasharray="3 4"
                fill="none"
                opacity="0.25"
              />
              {/* Animated traveling dash */}
              <motion.path
                d={path}
                stroke="url(#routeGrad)"
                strokeWidth="1.8"
                strokeLinecap="round"
                fill="none"
                strokeDasharray="60 800"
                initial={{ strokeDashoffset: 860 }}
                animate={{ strokeDashoffset: -60 }}
                transition={{
                  duration: 4,
                  repeat: Infinity,
                  delay: i * 0.5,
                  ease: "linear",
                }}
              />
            </g>
          );
        })}

        {/* Destination markers */}
        {DESTINATIONS.map((dest, i) => (
          <motion.g
            key={`dest-${i}`}
            initial={{ opacity: 0, scale: 0 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.3 + i * 0.1, type: "spring", damping: 12 }}
          >
            {/* Ping ring */}
            <circle cx={dest.x} cy={dest.y} r="6" fill="hsl(188, 75%, 50%)" opacity="0.3">
              <animate
                attributeName="r"
                values="4;14;4"
                dur="2.5s"
                begin={`${i * 0.3}s`}
                repeatCount="indefinite"
              />
              <animate
                attributeName="opacity"
                values="0.6;0;0.6"
                dur="2.5s"
                begin={`${i * 0.3}s`}
                repeatCount="indefinite"
              />
            </circle>
            <circle cx={dest.x} cy={dest.y} r="4.5" fill="hsl(188, 80%, 45%)" stroke="white" strokeWidth="1.5" />
            <text
              x={dest.x}
              y={dest.y - 12}
              fill="white"
              fontSize="11"
              fontWeight="600"
              textAnchor="middle"
              style={{ paintOrder: "stroke", stroke: "rgba(0,0,0,0.5)", strokeWidth: 2 }}
            >
              {language === "bn" ? dest.labelBn : dest.label}
            </text>
          </motion.g>
        ))}

        {/* Origin Hub — Bangladesh */}
        <g>
          {/* Outer glow */}
          <circle cx={ORIGIN.x} cy={ORIGIN.y} r="60" fill="url(#hubGlow)">
            <animate attributeName="r" values="50;70;50" dur="3s" repeatCount="indefinite" />
          </circle>
          {/* Pulse rings */}
          {[0, 1, 2].map((idx) => (
            <circle
              key={`pulse-${idx}`}
              cx={ORIGIN.x}
              cy={ORIGIN.y}
              r="10"
              fill="none"
              stroke="hsl(38, 95%, 60%)"
              strokeWidth="1.5"
              opacity="0"
            >
              <animate
                attributeName="r"
                values="10;45;10"
                dur="3s"
                begin={`${idx}s`}
                repeatCount="indefinite"
              />
              <animate
                attributeName="opacity"
                values="0.9;0;0.9"
                dur="3s"
                begin={`${idx}s`}
                repeatCount="indefinite"
              />
            </circle>
          ))}
          {/* Core */}
          <circle cx={ORIGIN.x} cy={ORIGIN.y} r="9" fill="hsl(38, 95%, 60%)" filter="url(#glow)" />
          <circle cx={ORIGIN.x} cy={ORIGIN.y} r="4" fill="white" />
          {/* Label */}
          <text
            x={ORIGIN.x}
            y={ORIGIN.y + 28}
            fill="hsl(38, 95%, 65%)"
            fontSize="14"
            fontWeight="800"
            textAnchor="middle"
            letterSpacing="1"
            style={{ paintOrder: "stroke", stroke: "rgba(0,0,0,0.6)", strokeWidth: 2.5 }}
          >
            {language === "bn" ? ORIGIN.labelBn.toUpperCase() : ORIGIN.label.toUpperCase()}
          </text>
          <text
            x={ORIGIN.x}
            y={ORIGIN.y + 42}
            fill="white"
            fontSize="8"
            fontWeight="600"
            textAnchor="middle"
            letterSpacing="2"
            opacity="0.8"
          >
            {ORIGIN.sub}
          </text>
        </g>
      </svg>

      {/* Country chips below map */}
      <div className="flex flex-wrap justify-center gap-2 mt-4 px-2">
        {DESTINATIONS.map((d, i) => (
          <motion.span
            key={d.label}
            initial={{ opacity: 0, y: 10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.6 + i * 0.05 }}
            className="inline-flex items-center gap-1.5 bg-white/10 backdrop-blur-md border border-white/20 text-white text-xs font-semibold px-3 py-1.5 rounded-full hover:bg-white/20 transition-colors"
          >
            <span className="text-base leading-none">{d.flag}</span>
            {language === "bn" ? d.labelBn : d.label}
          </motion.span>
        ))}
      </div>
    </div>
  );
};

export default AnimatedWorldMap;
