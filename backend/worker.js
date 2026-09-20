const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function clean(value, max = 500) {
  return String(value ?? "").replace(/[*_~|]/g, "").slice(0, max);
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
    if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

    const webhook = env.DISCORD_WEBHOOK_URL;
    if (!webhook) return json({ error: "Webhook is not configured" }, 500);

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON" }, 400);
    }

    const user = body?.user;
    const hatch = body?.hatch;
    if (!user || !hatch || !user.name || !hatch.pet) {
      return json({ error: "Missing hatch data" }, 400);
    }

    const variant = hatch.variant || {};
    const variantParts = [];
    if (variant.shiny) variantParts.push("Shiny");
    if (variant.mythic) variantParts.push("Mythic");
    if (variant.xl) variantParts.push("XL");

    const embed = {
      title: "# " + clean(hatch.pet),
      description: "User: " + clean(user.name),
      fields: [
        {
          name: "User Info",
          value: [
            "User: **" + clean(user.name) + "**",
            "Display Name: **" + clean(user.displayName) + "**",
            "User ID: **" + clean(user.userId) + "**",
          ].join("\n"),
          inline: false,
        },
        {
          name: "Hatch Info",
          value: [
            "Pet: **" + clean(hatch.pet) + "**",
            "Rarity: **" + clean(hatch.rarity) + "**",
            "Egg: **" + clean(hatch.egg) + "**",
            "Variant: **" + clean(variantParts.length ? variantParts.join(" ") : "Normal") + "**",
          ].join("\n"),
          inline: false,
        },
      ],
      timestamp: new Date().toISOString(),
    };

    const discordResponse = await fetch(webhook, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ embeds: [embed] }),
    });

    if (!discordResponse.ok) return json({ error: "Discord request failed" }, 502);
    return json({ ok: true });
  },
};
