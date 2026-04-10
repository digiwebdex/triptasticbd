import { Link } from "react-router-dom";
import { CheckCircle, ArrowRight, LayoutDashboard } from "lucide-react";

interface Props {
  bookingId: string;
  trackingId: string;
  userId: string;
}

const BookingSuccess = ({ bookingId, trackingId, userId }: Props) => {
  const isGuest = !userId;
  const dashboardLink = isGuest ? `/track?id=${trackingId}` : "/dashboard";

  return (
    <div className="space-y-6">
      <div className="bg-card border border-primary/30 rounded-xl p-8 text-center">
        <CheckCircle className="h-16 w-16 text-primary mx-auto mb-4" />
        <h2 className="font-heading text-2xl font-bold mb-2">Booking Confirmed!</h2>
        <p className="text-muted-foreground mb-3">Your tracking ID is:</p>
        <p className="text-2xl font-heading font-bold text-primary mb-4">{trackingId}</p>
        <p className="text-sm text-muted-foreground">
          Save this ID to track your booking status anytime.
        </p>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <Link
          to={`/track?id=${trackingId}`}
          className="flex-1 py-3 rounded-md text-sm font-semibold text-center inline-flex items-center justify-center gap-2 bg-gradient-gold text-primary-foreground hover:opacity-90 transition-opacity shadow-gold"
        >
          Track Booking <ArrowRight className="h-4 w-4" />
        </Link>
        <Link
          to={dashboardLink}
          className="flex-1 py-3 rounded-md text-sm font-semibold text-center inline-flex items-center justify-center gap-2 border border-border text-foreground hover:bg-secondary transition-colors"
        >
          <LayoutDashboard className="h-4 w-4" />
          {isGuest ? "View Booking" : "Go to Dashboard"}
        </Link>
      </div>
    </div>
  );
};

export default BookingSuccess;
