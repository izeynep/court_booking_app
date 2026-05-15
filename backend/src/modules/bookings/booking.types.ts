export type CreateBookingBody = {
  courtName?: string;
  courtId?: string;
  price?: number;
  startAt?: string;
};

export type BookingRow = {
  id: string;
  firebase_uid: string;
  court_name: string;
  court_id: string | null;
  price: number;
  start_at: Date;
  end_at: Date;
  status: 'confirmed' | 'cancelled';
  created_at: Date;
};

export type BookingResponse = {
  id: string;
  courtName: string;
  courtId: string | null;
  price: number;
  startAt: string;
  endAt: string;
  status: 'confirmed' | 'cancelled';
  createdAt: string;
};
