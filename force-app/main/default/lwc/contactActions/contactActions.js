import { LightningElement, api, track, wire } from "lwc";
import candidateCreate from "@salesforce/apex/CVTransformerApi.candidateCreate";
import dataGet from "@salesforce/apex/CVTransformerApi.dataGet";
import configurationUpsert from "@salesforce/apex/CVTransformerApi.configurationUpsert";
import contactAttachmentsSync from "@salesforce/apex/CVTransformerApi.contactAttachmentsSync";
import candidateAttachmentsSync from "@salesforce/apex/CVTransformerApi.candidateAttachmentsSync";
import pdfGenerate from "@salesforce/apex/CVTransformerApi.pdfGenerate";

export default class ContactActions extends LightningElement {
  @api recordId;
  @track data = {};
  error;
  state = "loading";

  organization_id;
  candidate_id;
  candidate_secret_editable;

  @wire(dataGet, { contact_id: "$recordId" })
  wiredData({ error, data }) {
    if (data) {
      this.data = data;
      this.error = null;
      this.state = this.data.organization_id ? "edit" : "configure";
    } else if (error) {
      this.data = {};
      this.error = error;
      this.state = "error";
    }
  }

  get isLoading() {
    return this.state === "loading";
  }

  get isEdit() {
    return this.state === "edit";
  }

  get isConfigure() {
    return this.state === "configure";
  }

  get isError() {
    return this.state === "error";
  }

  get iframeUrl() {
    return `https://www.cv-transformer.com/candidates/${this.data.candidate_id}?s=${this.data.candidate_secret}`;
  }

  onConfigure() {
    this.state = "configure";
  }

  onConfigureCancel() {
    this.state = "edit";
  }

  async onConfigureSubmit(event) {
    event.preventDefault();
    this.state = "loading";
    try {
      const organization_id = await configurationUpsert({
        api_key: event.target.api_key.value
      });
      this.data = { ...this.data, organization_id };
      this.error = null;
      this.state = "edit";
    } catch (error) {
      this.data = {};
      this.error = error.body.message;
      this.state = "configure";
    }
  }

  async onCandidateCreate() {
    this.state = "loading";
    try {
      this.data = await candidateCreate({ contact_id: this.recordId });
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }

  async onContactAttachmentsSync() {
    this.state = "loading";
    try {
      await contactAttachmentsSync({ contact_id: this.recordId });
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }

  async onCandidateAttachmentsSync() {
    this.state = "loading";
    try {
      await candidateAttachmentsSync({ contact_id: this.recordId });
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }

  async onPdfGenerate() {
    this.state = "loading";
    try {
      await pdfGenerate({ contact_id: this.recordId });
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }
}
