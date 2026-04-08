import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@13";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
});

const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Signature manquante", { status: 400 });
  }

  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    return new Response(`Signature invalide: ${err.message}`, { status: 400 });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  switch (event.type) {
    case "payment_intent.succeeded": {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      const missionId = paymentIntent.metadata.mission_id;

      // Mettre à jour le paiement
      await supabase
        .from("payments")
        .update({
          status: "completed",
          paid_at: new Date().toISOString(),
          callback_data: paymentIntent,
        })
        .eq("provider_payment_id", paymentIntent.id);

      // Mettre à jour la mission
      await supabase
        .from("missions")
        .update({ status: "completed", completed_at: new Date().toISOString() })
        .eq("id", missionId);

      // Notifier le client et le prestataire
      const { data: mission } = await supabase
        .from("missions")
        .select("client_id, prestataire_id")
        .eq("id", missionId)
        .single();

      if (mission) {
        await supabase.from("notifications").insert([
          {
            user_id: mission.client_id,
            title: "Paiement confirmé",
            body: "Votre paiement a été validé avec succès.",
            data: { mission_id: missionId, type: "payment_success" },
          },
          {
            user_id: mission.prestataire_id,
            title: "Mission payée",
            body: "Le paiement de la mission a été confirmé.",
            data: { mission_id: missionId, type: "payment_success" },
          },
        ]);
      }
      break;
    }

    case "payment_intent.payment_failed": {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;

      await supabase
        .from("payments")
        .update({
          status: "failed",
          callback_data: paymentIntent,
        })
        .eq("provider_payment_id", paymentIntent.id);

      break;
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
