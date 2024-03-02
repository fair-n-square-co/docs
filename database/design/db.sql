CREATE TABLE "group" (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "name" varchar,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "user" (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "username" varchar,
  "firstname" varchar,
  "lastname" varchar,
  "email" varchar,
  "phone_number" varchar,
  "profile_image" varchar,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "group_user" (
  "user_id" uuid,
  "group_id" uuid,
  PRIMARY KEY ("user_id", "group_id")
);

CREATE TABLE "transaction" (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "group_id" uuid,
  "creator_id" uuid,
  "last_updated_user_id" uuid,
  "amount" varchar,
  "description" text,
  "expense_type" enum,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "transaction_user" (
  "transaction_id" uuid,
  "user_id" uuid,
  "amount" varchar,
  "person_type" enum,
  PRIMARY KEY ("transaction_id", "user_id")
);

-- COMMENT ON COLUMN "transaction"."expense_type" IS 'payment, settle';

-- COMMENT ON COLUMN "transaction_user"."person_type" IS 'payer, payee';

ALTER TABLE "group_user" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id");

ALTER TABLE "group_user" ADD FOREIGN KEY ("group_id") REFERENCES "group" ("id");

ALTER TABLE "transaction" ADD FOREIGN KEY ("group_id") REFERENCES "group" ("id");

ALTER TABLE "transaction" ADD FOREIGN KEY ("creator_id") REFERENCES "user" ("id");

ALTER TABLE "transaction" ADD FOREIGN KEY ("last_updated_user_id") REFERENCES "user" ("id");

ALTER TABLE "transaction_user" ADD FOREIGN KEY ("transaction_id") REFERENCES "transaction" ("id");

ALTER TABLE "transaction_user" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id");
