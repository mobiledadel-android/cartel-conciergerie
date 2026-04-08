import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@13";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
});

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Vérifier l'authentification
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Non autorisé" }), {
        status: 401,
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Token invalide" }), {
        status: 401,
      });
    }

    const { mission_id } = await req.json();

    // Récupérer la mission
    const { data: mission, error: missionError } = await supabase
      .from("missions")
      .select("*")
      .eq("id", mission_id)
      .eq("client_id", user.id)
      .single();

    if (missionError || !mission) {
      return new Response(JSON.stringify({ error: "Mission introuvable" }), {
        status: 404,
      });
    }

    // Calculer la commission (15%)
    const commissionRate = 0.15;
    const commissionAmount = Math.round(mission.total_price * commissionRate * 100) / 100;

    // Créer le PaymentIntent Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(mission.total_price * 100), // en centimes
      currency: "eur",
      metadata: {
        mission_id: mission.id,
        client_id: user.id,
      },
    });

    // Enregistrer le paiement en BDD
    await supabase.from("payments").insert({
      mission_id: mission.id,
      client_id: user.id,
      amount: mission.total_price,
      commission_amount: commissionAmount,
      provider: "stripe",
      provider_payment_id: paymentIntent.id,
      status: "processing",
    });

    return new Response(
      JSON.stringify({
        client_secret: paymentIntent.client_secret,
        payment_intent_id: paymentIntent.id,
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
    });
  }
});
