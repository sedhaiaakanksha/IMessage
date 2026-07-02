import express from "express";
import User from "../models/User";
import { verifyWebhook } from "@clerk/backend/webhooks";

const router = express.Router();

router.post("/", async (req, res) => {
  console.log("Webhook hit");

  try {
    const signingSecret = process.env.CLERK_WEBHOOK_SIGNING_SECRET;

    if (!signingSecret) {
      return res
        .status(503)
        .json({ message: "Webhook secret is not provided" });
    }

    const payload = req.body.toString("utf8");

    const evt = await verifyWebhook(payload, req.headers, signingSecret);

    console.log("Webhook event:", evt.type);

    const u = evt.data;

    if (evt.type === "user.created" || evt.type === "user.updated") {
      const email =
        u.email_addresses?.find((e) => e.id === u.primary_email_address_id)
          ?.email_address ?? u.email_addresses?.[0]?.email_address;

      const fullName =
        [u.first_name, u.last_name].filter(Boolean).join(" ") ||
        u.username ||
        email?.split("@")[0];

      console.log("About to update database");

      await User.findOneAndUpdate(
        { clerkId: u.id },
        {
          clerkId: u.id,
          email,
          fullName,
          profilePic: u.image_url,
        },
        { new: true, upsert: true },
      );
    }

    if (evt.type === "user.deleted") {
      await User.findOneAndDelete({ clerkId: u.id });
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error("Webhook error:", error);
    return res.status(400).json({ message: "Webhook verification failed" });
  }
});

export default router;
