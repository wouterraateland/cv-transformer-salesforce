import { LightningElement, api, track, wire } from "lwc";
import candidateAttachCV from "@salesforce/apex/CVTransformerApi.candidateAttachCV";
import candidateCreate from "@salesforce/apex/CVTransformerApi.candidateCreate";
import candidateLink from "@salesforce/apex/CVTransformerApi.candidateLink";
import candidateUnlink from "@salesforce/apex/CVTransformerApi.candidateUnlink";
import configUpdate from "@salesforce/apex/CVTransformerApi.configUpdate";
import configUpsert from "@salesforce/apex/CVTransformerApi.configUpsert";
import dataGet from "@salesforce/apex/CVTransformerApi.dataGet";

export default class CVTransformer extends LightningElement {
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
      this.state = this.data.organization_id ? "edit" : "setup";
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

  get isSetup() {
    return this.state === "setup";
  }

  get isConfigure() {
    return this.state === "configure";
  }

  get isError() {
    return this.state === "error";
  }

  get iframeUrl() {
    let url = `https://www.cv-transformer.com/candidates/${this.data.candidate_id}?s=${this.data.candidate_secret}`;
    if (this.data.color_scheme)
      url += `&color_scheme=${this.data.color_scheme}`;
    if (this.data.language) url += `&language=${this.data.language}`;
    return url;
  }

  onConfigure() {
    this.error = null;
    this.state = "configure";
  }

  onConfigureCancel() {
    this.error = null;
    this.state = "edit";
  }

  onSetup() {
    this.error = null;
    this.state = "setup";
  }

  onSetupCancel() {
    this.error = null;
    this.state = "edit";
  }

  async onSetupSubmit(event) {
    event.preventDefault();
    this.state = "loading";
    try {
      const organization_id = await configUpsert({
        api_key: event.target.api_key.value
      });
      this.data = { ...this.data, organization_id };
      this.error = null;
      this.state = "edit";
    } catch (error) {
      this.data = {};
      this.error = error.body.message;
      this.state = "setup";
    }
  }

  get languageWithDefault() {
    return this.data.language || "en";
  }
  languageOptions = [
    { label: "English", value: "en" },
    { label: "Deutsch", value: "de" },
    { label: "Français", value: "fr" },
    { label: "Nederlands", value: "nl" }
  ];
  async onLanguageChange(event) {
    const language = event.detail.value;
    this.state = "loading";
    try {
      await configUpdate({ color_schema: this.data.color_schema, language });
      this.data = { ...this.data, language };
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "configure";
  }

  get colorSchemeWithDefault() {
    return this.data.color_scheme || "";
  }
  colorSchemeOptions = [
    { label: "System default", value: "" },
    { label: "Light", value: "light" },
    { label: "Dark", value: "dark" }
  ];
  async onColorSchemeChange(event) {
    const color_scheme = event.detail.value;
    this.state = "loading";
    try {
      await configUpdate({ color_scheme, language: this.data.language });
      this.data = { ...this.data, color_scheme };
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "configure";
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

  async onCandidateSelect() {
    // eslint-disable-next-line no-alert
    const candidate_id = prompt(
      "Enter candidate ID. (https://cv-transformer.com/organizations/{{organization_id}}/candidates/{{candidate_id}})"
    );
    if (!candidate_id) return;
    this.state = "loading";
    try {
      this.data = await candidateLink({
        contact_id: this.recordId,
        candidate_id
      });
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }

  async onCandidateUnlink() {
    this.state = "loading";
    try {
      await candidateUnlink({ contact_id: this.recordId });
      this.data = { ...this.data, candidate_id: null, candidate_secret: null };
      this.error = null;
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }

  async onAttachmentSelect(event) {
    this.state = "loading";
    try {
      await candidateAttachCV({
        contact_id: this.recordId,
        content_version_id: event.detail
      });
    } catch (error) {
      this.error = error.body.message;
    }
    this.state = "edit";
  }
}
